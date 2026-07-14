import Foundation
import Combine

/// The heart of FocusPulse: a strictly-typed state machine that drives the countdown and
/// auto-cycles between work and break sessions.
///
/// Accuracy: the engine never does `seconds -= 1`. It derives `remainingSeconds` from the
/// difference between an injectable clock (`now`) and `expectedEndDate`, so it stays correct
/// even if the run loop stalls or the app is backgrounded and later restored (Story 1.2, 1.4).
///
/// Testability: `tick()` is the single logic entry point. Production wires a 1 Hz
/// `Timer.publish` into it; tests advance a controllable clock and call `tick()` directly.
@MainActor
public final class TimerEngine: ObservableObject {
    @Published public private(set) var state: TimerState = .idle
    @Published public private(set) var sessionType: SessionType = .work
    @Published public private(set) var remainingSeconds: Int
    @Published public private(set) var completedWorkSessions: Int = 0

    public private(set) var configuration: TimerConfiguration
    public private(set) var expectedEndDate: Date?

    /// Invoked when a session finishes (reached zero or was skipped) so the app can persist a
    /// `FocusSession`. Not called for a hard `stop()` (which abandons the current session).
    public var onSessionCompleted: ((_ type: SessionType, _ start: Date, _ end: Date) -> Void)?

    private let cycler: SessionCycler
    private let now: () -> Date
    private var currentSessionStart: Date?
    private var pausedRemaining: TimeInterval?
    private var ticker: AnyCancellable?

    public init(
        configuration: TimerConfiguration = .default,
        now: @escaping () -> Date = { Date() }
    ) {
        self.configuration = configuration
        self.cycler = SessionCycler(longBreakInterval: configuration.longBreakInterval)
        self.now = now
        self.remainingSeconds = Int(configuration.duration(for: .work).rounded())
    }

    // MARK: - Intents

    /// Start a fresh cycle from Idle/Completed. No-op otherwise.
    public func start() {
        guard state == .idle || state == .completed else { return }
        completedWorkSessions = 0
        begin(.work)
    }

    /// Pause a running timer, freezing the remaining time.
    public func pause() {
        guard state == .running, let end = expectedEndDate else { return }
        pausedRemaining = max(0, end.timeIntervalSince(now()))
        remainingSeconds = Int((pausedRemaining ?? 0).rounded(.up))
        expectedEndDate = nil
        state = .paused
        stopTicking()
    }

    /// Resume a paused timer from where it left off.
    public func resume() {
        guard state == .paused, let remaining = pausedRemaining else { return }
        expectedEndDate = now().addingTimeInterval(remaining)
        pausedRemaining = nil
        state = .running
        startTicking()
    }

    /// Toggle between running and paused.
    public func togglePlayPause() {
        switch state {
        case .running: pause()
        case .paused: resume()
        case .idle, .completed: start()
        }
    }

    /// Stop and reset the whole cycle. The in-flight session is abandoned (not persisted here).
    public func stop() {
        stopTicking()
        state = .idle
        sessionType = .work
        expectedEndDate = nil
        pausedRemaining = nil
        currentSessionStart = nil
        completedWorkSessions = 0
        remainingSeconds = Int(configuration.duration(for: .work).rounded())
    }

    /// Skip the current session and advance immediately to the next in the cycle.
    public func skip() {
        guard state == .running || state == .paused else { return }
        complete(reachedEnd: false)
    }

    /// Recompute remaining time from the clock; complete the session when it reaches zero.
    public func tick() {
        guard state == .running, let end = expectedEndDate else { return }
        let remaining = end.timeIntervalSince(now())
        if remaining <= 0 {
            remainingSeconds = 0
            complete(reachedEnd: true)
        } else {
            remainingSeconds = Int(remaining.rounded(.up))
        }
    }

    /// Apply a new configuration. Takes effect on the next session, never mid-session.
    public func updateConfiguration(_ configuration: TimerConfiguration) {
        self.configuration = configuration
        if state == .idle {
            remainingSeconds = Int(configuration.duration(for: sessionType).rounded())
        }
    }

    // MARK: - Machinery

    private func begin(_ type: SessionType) {
        let duration = configuration.duration(for: type)
        sessionType = type
        currentSessionStart = now()
        expectedEndDate = now().addingTimeInterval(duration)
        remainingSeconds = Int(duration.rounded())
        state = .running
        startTicking()
    }

    private func complete(reachedEnd: Bool) {
        stopTicking()
        let finished = sessionType
        if let start = currentSessionStart {
            onSessionCompleted?(finished, start, now())
        }
        if finished == .work {
            completedWorkSessions += 1
        }
        let next = cycler.next(after: finished, completedWorkSessions: completedWorkSessions)
        begin(next)
    }

    private func startTicking() {
        stopTicking()
        ticker = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            }
    }

    private func stopTicking() {
        ticker?.cancel()
        ticker = nil
    }
}
