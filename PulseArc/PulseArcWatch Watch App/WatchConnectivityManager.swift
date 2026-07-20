import Foundation
import WatchConnectivity
import PulseArcCore

// NOTE: Source for the PulseArc Apple Watch app — NOT part of the iOS app target's synchronized
// group, so it never compiles into the phone app. Wire it into a watchOS target (see README.md).

/// Apple Watch side of the PulseArc ↔ iPhone state bridge (Story 7.4 / architecture §8.3).
///
/// Thin WatchConnectivity transport, symmetric to the iPhone's `PhoneConnectivityManager`. Every
/// decision defers to the verified `PulseArcCore` policy (`TimerReconciler` / `TimerAuthority`),
/// which is unit-tested in `WatchSyncTests` — so there is nothing here worth testing.
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    /// A snapshot arrived from the phone (the view model reconciles it).
    var onRemoteSnapshot: ((TimerSnapshot) -> Void)?
    /// The phone forwarded a control command for this (owning) device to apply.
    var onCommandFromPhone: ((SyncCommand) -> Void)?

    private var session: WCSession? { WCSession.isSupported() ? .default : nil }

    /// Whether the iPhone app is reachable right now for a live `sendMessage`.
    var isPeerReachable: Bool { session?.isReachable ?? false }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Publish this device's snapshot to the phone. Always mirrors into `applicationContext`
    /// (catch-up on wake) and additionally uses `sendMessage` when the phone is reachable.
    func publish(snapshot: TimerSnapshot) {
        guard let session, session.activationState == .activated,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? session.updateApplicationContext([Key.snapshot: data])
        if session.isReachable {
            session.sendMessage([Key.snapshot: data], replyHandler: nil, errorHandler: nil)
        }
    }

    /// Forward a control command to the phone (used when the phone owns the active session).
    func send(command: SyncCommand) {
        guard let session, session.isReachable else { return }
        session.sendMessage([Key.command: command.rawValue], replyHandler: nil, errorHandler: nil)
    }

    private enum Key { static let snapshot = "snapshot"; static let command = "command" }

    private func handle(_ message: [String: Any]) {
        if let data = message[Key.snapshot] as? Data,
           let remote = try? JSONDecoder().decode(TimerSnapshot.self, from: data) {
            DispatchQueue.main.async { [weak self] in self?.onRemoteSnapshot?(remote) }
        }
        if let raw = message[Key.command] as? String, let command = SyncCommand(rawValue: raw) {
            DispatchQueue.main.async { [weak self] in self?.onCommandFromPhone?(command) }
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    // watchOS requires only the activation callback (inactive/deactivate are iOS-only).
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) { handle(message) }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) { handle(applicationContext) }
}
