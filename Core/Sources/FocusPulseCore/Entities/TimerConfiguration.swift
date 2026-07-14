import Foundation

/// User-configurable timer settings. Durations are stored in seconds. All values are
/// clamped to safe bounds on init (NASA Power-of-10 input validation, architecture §5).
public struct TimerConfiguration: Equatable, Sendable {
    public let workDuration: TimeInterval
    public let shortBreakDuration: TimeInterval
    public let longBreakDuration: TimeInterval
    /// Every Nth completed work session triggers a Long Break (2...8, default 4).
    public let longBreakInterval: Int

    public init(
        workMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        longBreakInterval: Int = 4
    ) {
        self.workDuration = TimeInterval(workMinutes.clamped(to: 1...120) * 60)
        self.shortBreakDuration = TimeInterval(shortBreakMinutes.clamped(to: 1...60) * 60)
        self.longBreakDuration = TimeInterval(longBreakMinutes.clamped(to: 1...60) * 60)
        self.longBreakInterval = longBreakInterval.clamped(to: 2...8)
    }

    /// The configured duration (seconds) for a given session type.
    public func duration(for type: SessionType) -> TimeInterval {
        switch type {
        case .work: return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }

    public static let `default` = TimerConfiguration()
}

extension Comparable {
    /// Clamp a value into a closed range.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
