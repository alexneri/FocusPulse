import Foundation

/// Derived daily aggregate produced by `StatisticsEngine` (never persisted as source of truth).
public struct DailyStat: Equatable, Sendable, Identifiable {
    /// Start-of-day for the represented date.
    public let date: Date
    public let totalFocusTime: TimeInterval
    public let sessionsCompleted: Int

    public var id: Date { date }

    public init(date: Date, totalFocusTime: TimeInterval, sessionsCompleted: Int) {
        self.date = date
        self.totalFocusTime = totalFocusTime
        self.sessionsCompleted = sessionsCompleted
    }
}
