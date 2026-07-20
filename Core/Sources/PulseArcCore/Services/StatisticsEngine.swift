import Foundation

/// Domain service that derives insight metrics from a set of sessions. Pure and value-typed:
/// it reads sessions and produces results, owning no persistence. Only completed *work*
/// sessions count toward focus metrics.
public struct StatisticsEngine: Sendable {
    public let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    private func completedWork(_ sessions: [FocusSession]) -> [FocusSession] {
        sessions.filter { $0.type == .work && $0.status == .completed }
    }

    /// Total focused time across all completed work sessions.
    public func totalFocusTime(_ sessions: [FocusSession]) -> TimeInterval {
        completedWork(sessions).reduce(0) { $0 + $1.duration }
    }

    /// Per-day aggregates, ascending by date. Days with no work sessions are omitted.
    public func dailyStats(_ sessions: [FocusSession]) -> [DailyStat] {
        let groups = Dictionary(grouping: completedWork(sessions)) {
            calendar.startOfDay(for: $0.startTime)
        }
        return groups
            .map { day, items in
                DailyStat(
                    date: day,
                    totalFocusTime: items.reduce(0) { $0 + $1.duration },
                    sessionsCompleted: items.count
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Consecutive-day streak ending at `reference` (or the day before, if nothing today yet).
    public func currentStreak(_ sessions: [FocusSession], asOf reference: Date) -> Int {
        let days = Set(completedWork(sessions).map { calendar.startOfDay(for: $0.startTime) })
        guard !days.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: reference)
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  days.contains(yesterday) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// Hour of day (0...23) with the most accumulated focus time, if any.
    public func bestFocusHour(_ sessions: [FocusSession]) -> Int? {
        var byHour: [Int: TimeInterval] = [:]
        for session in completedWork(sessions) {
            let hour = calendar.component(.hour, from: session.startTime)
            byHour[hour, default: 0] += session.duration
        }
        return byHour.max { $0.value < $1.value }?.key
    }
}
