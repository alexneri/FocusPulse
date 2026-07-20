import Foundation
import WatchConnectivity
import PulseArcCore

/// iPhone side of the PulseArc ↔ Apple Watch state bridge (Story 7.4 / architecture §8.3).
///
/// This is a thin WatchConnectivity **transport**. Every decision — who owns the session, which
/// snapshot wins a conflict — is delegated to the verified `PulseArcCore` policy
/// (`TimerReconciler` / `TimerAuthority`), so there is no business logic here worth unit-testing;
/// the logic that matters lives in `WatchSync.swift` and is covered by `WatchSyncTests`.
///
/// It is inert until wired. Create it once from the app's `TimerEngine` adapter, call
/// `activate()`, then `publish(...)` on every timer transition, and set `onRemoteSnapshot` /
/// `onCommandFromWatch` to receive. See `PulseArcWatch/README.md` for the end-to-end wiring.
final class PhoneConnectivityManager: NSObject {
    static let shared = PhoneConnectivityManager()

    /// A newer snapshot arrived from the watch and won reconciliation — apply it to the local engine.
    var onRemoteSnapshot: ((TimerSnapshot) -> Void)?
    /// The watch forwarded a control command for this (owning) device to apply.
    var onCommandFromWatch: ((SyncCommand) -> Void)?

    private var latest: TimerSnapshot?
    private var revision: UInt64 = 0

    private var session: WCSession? { WCSession.isSupported() ? .default : nil }

    /// Whether the counterpart Apple Watch app is reachable for a live `sendMessage`.
    var isPeerReachable: Bool { session?.isReachable ?? false }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - Publish

    /// Mirror the current local timer state to the watch. Always writes `applicationContext` (so a
    /// sleeping watch catches up on wake) and additionally uses `sendMessage` when it is reachable
    /// (immediate). The monotonic `revision` and `.phone` origin let the watch reconcile
    /// deterministically.
    func publish(
        state: PulseArcCore.TimerState,
        sessionType: PulseArcCore.SessionType,
        remainingSeconds: Int,
        totalSeconds: Int,
        expectedEndDate: Date?,
        completedWorkSessions: Int,
        owner: DeviceRole?
    ) {
        revision &+= 1
        let snapshot = TimerSnapshot(
            state: state, sessionType: sessionType, remainingSeconds: remainingSeconds,
            expectedEndDate: expectedEndDate, completedWorkSessions: completedWorkSessions,
            owner: owner, revision: revision, origin: .phone, updatedAt: Date(),
            totalSeconds: totalSeconds
        )
        latest = snapshot
        guard let session, session.activationState == .activated,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? session.updateApplicationContext([Key.snapshot: data])
        if session.isReachable {
            session.sendMessage([Key.snapshot: data], replyHandler: nil, errorHandler: nil)
        }
    }

    /// Forward a control command to the watch (used when the watch owns the active session).
    func send(command: SyncCommand) {
        guard let session, session.isReachable else { return }
        session.sendMessage([Key.command: command.rawValue], replyHandler: nil, errorHandler: nil)
    }

    // MARK: - Receive

    private enum Key { static let snapshot = "snapshot"; static let command = "command" }

    private func handle(_ message: [String: Any]) {
        if let data = message[Key.snapshot] as? Data,
           let remote = try? JSONDecoder().decode(TimerSnapshot.self, from: data) {
            let local = latest ?? .idle(origin: .phone, at: Date())
            if TimerReconciler.resolve(local: local, remote: remote) == .takeRemote {
                latest = remote
                DispatchQueue.main.async { [weak self] in self?.onRemoteSnapshot?(remote) }
            }
        }
        if let raw = message[Key.command] as? String, let command = SyncCommand(rawValue: raw) {
            DispatchQueue.main.async { [weak self] in self?.onCommandFromWatch?(command) }
        }
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    // Re-activate to keep serving a newly-paired watch after a switch.
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) { handle(message) }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) { handle(applicationContext) }
}
