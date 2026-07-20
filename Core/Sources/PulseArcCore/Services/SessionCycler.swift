import Foundation

/// Pure logic that decides which session comes next in the auto-cycle.
/// Work → Short Break, except every `longBreakInterval`-th completed work session → Long Break.
/// Any break → Work.
public struct SessionCycler: Sendable {
    public let longBreakInterval: Int

    public init(longBreakInterval: Int = 4) {
        self.longBreakInterval = max(2, longBreakInterval)
    }

    /// - Parameters:
    ///   - type: the session that just completed.
    ///   - completedWorkSessions: total work sessions completed *including* the one that just
    ///     finished (so after the 4th work session this is 4).
    public func next(after type: SessionType, completedWorkSessions: Int) -> SessionType {
        switch type {
        case .work:
            let dueLongBreak = completedWorkSessions > 0
                && completedWorkSessions % longBreakInterval == 0
            return dueLongBreak ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }
}
