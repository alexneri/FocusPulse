import Foundation
import Combine
import SwiftUI
import WatchKit
import FocusPulseCore

// NOTE: FocusPulse Apple Watch source — NOT compiled into the iOS app target. See README.md.

/// Presentation adapter for the Apple Watch timer face (Stories 7.2 / 7.3 / 7.4 / 7.6).
///
/// The view renders from a single `display: TimerSnapshot`. Two modes, chosen by the sync policy:
///   • **local**  — the watch started the session, so its `FocusPulseCore.TimerEngine` drives and
///     publishes snapshots (`owner == .watch`).
///   • **mirror** — the iPhone owns the session; we render the snapshot it sends and forward taps.
///
/// Timing is drift-safe in both modes: the core derives remaining time from a clock diff, and the
/// running countdown reads `expectedEndDate` directly — never a decrementing counter.
@MainActor
final class WatchTimerViewModel: ObservableObject {
    @Published private(set) var display: TimerSnapshot

    private let core: FocusPulseCore.TimerEngine
    private let connectivity = WatchConnectivityManager.shared
    private var revision: UInt64 = 0
    private var cancellables = Set<AnyCancellable>()

    init(configuration: TimerConfiguration = .default) {
        let core = FocusPulseCore.TimerEngine(configuration: configuration)
        self.core = core
        self.display = Self.coldLaunchSnapshot(
            fallbackRemaining: core.remainingSeconds,
            total: Int(configuration.duration(for: .work))
        )

        core.objectWillChange
            .sink { [weak self] _ in self?.syncFromCore() }
            .store(in: &cancellables)
        core.onSessionCompleted = { _, _, _ in
            WKInterfaceDevice.current().play(.success)
        }

        connectivity.onRemoteSnapshot = { [weak self] remote in self?.adopt(remote) }
        connectivity.onCommandFromPhone = { [weak self] command in self?.applyLocally(command) }
        connectivity.activate()
    }

    // MARK: - Derived view state

    /// Elapsed fraction (0…1) for the ring; 0 when idle or the total is unknown.
    var progress: Double {
        guard display.totalSeconds > 0 else { return 0 }
        let remaining = Double(max(0, display.remainingSeconds))
        return min(1, max(0, 1 - remaining / Double(display.totalSeconds)))
    }

    /// Number of the four cycle dots that are filled.
    var cycleFilled: Int { display.completedWorkSessions % 4 }

    // MARK: - Controls (routed through the authority policy)

    func primaryTapped() {
        let command: SyncCommand = !display.isActive
            ? .start
            : (display.state == .running ? .pause : .resume)
        route(command)
    }
    func skipTapped() { route(.skip) }
    func stopTapped() { route(.stop) }

    private func route(_ command: SyncCommand) {
        switch TimerAuthority.route(command: command, snapshot: display,
                                    thisDevice: .watch, peerReachable: connectivity.isPeerReachable) {
        case .forwardToPeer:
            connectivity.send(command: command)
            WKInterfaceDevice.current().play(.click)
        case .applyLocally:
            applyLocally(command)
        }
    }

    private func applyLocally(_ command: SyncCommand) {
        switch command {
        case .start:  core.start()
        case .pause:  core.pause()
        case .resume: core.resume()
        case .skip:   core.skip()
        case .stop:   core.stop()
        }
        WKInterfaceDevice.current().play(command == .stop ? .stop : .click)
        syncFromCore()
    }

    // MARK: - Sync

    /// Local core changed → this device becomes the render + publish source (`owner == .watch`).
    private func syncFromCore() {
        revision &+= 1
        let total = Int(core.configuration.duration(for: core.sessionType))
        display = TimerSnapshot(
            state: core.state, sessionType: core.sessionType,
            remainingSeconds: core.remainingSeconds, expectedEndDate: core.expectedEndDate,
            completedWorkSessions: core.completedWorkSessions,
            owner: core.state == .idle ? nil : .watch,
            revision: revision, origin: .watch, updatedAt: Date(), totalSeconds: total
        )
        persistShared()
        connectivity.publish(snapshot: display)
        objectWillChange.send()
    }

    /// A snapshot arrived from the phone; adopt it only if it wins reconciliation.
    private func adopt(_ remote: TimerSnapshot) {
        guard TimerReconciler.resolve(local: display, remote: remote) == .takeRemote else { return }
        display = remote
        if !remote.isActive { core.stop() }   // phone stopped → reset our engine so a local Start is clean
        persistShared()
        objectWillChange.send()
    }

    private func persistShared() {
        let shared = SharedTimerState(
            stateRaw: display.state.rawValue, sessionTypeRaw: display.sessionType.rawValue,
            remainingSeconds: display.remainingSeconds, expectedEndDate: display.expectedEndDate,
            isRunning: display.state == .running
        )
        if let data = try? JSONEncoder().encode(shared) {
            AppGroup.defaults?.set(data, forKey: SharedTimerState.key)
        }
    }

    private static func coldLaunchSnapshot(fallbackRemaining: Int, total: Int) -> TimerSnapshot {
        if let data = AppGroup.defaults?.data(forKey: SharedTimerState.key),
           let shared = try? JSONDecoder().decode(SharedTimerState.self, from: data) {
            let state = TimerState(rawValue: shared.stateRaw) ?? .idle
            let type = SessionType(rawValue: shared.sessionTypeRaw) ?? .work
            let active = state == .running || state == .paused
            return TimerSnapshot(
                state: state, sessionType: type, remainingSeconds: shared.remainingSeconds,
                expectedEndDate: shared.expectedEndDate, completedWorkSessions: 0,
                owner: active ? .phone : nil, revision: 0, origin: .phone, updatedAt: Date(),
                totalSeconds: total
            )
        }
        return TimerSnapshot(
            state: .idle, sessionType: .work, remainingSeconds: fallbackRemaining,
            expectedEndDate: nil, completedWorkSessions: 0, owner: nil, revision: 0,
            origin: .phone, updatedAt: Date(), totalSeconds: total
        )
    }
}
