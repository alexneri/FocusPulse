import SwiftUI
import FocusPulseCore

/// GitHub-style contribution heatmap of focus consistency over the last 12 weeks (Story 3.3).
/// One cell per day; opacity scales with that day's completed focus minutes.
struct FocusHeatmap: View {
    let sessions: [FocusSession]

    private let weeks = 12
    private let cell: CGFloat = 13
    private let spacing: CGFloat = 3

    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let firstColumn = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeekStart) ?? today
        let minutesByDay = focusMinutesByDay(calendar: calendar)
        let maxMinutes = max(minutesByDay.values.max() ?? 0, 1)

        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<weeks, id: \.self) { week in
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { weekday in
                        let day = calendar.date(byAdding: .day, value: week * 7 + weekday, to: firstColumn) ?? today
                        RoundedRectangle(cornerRadius: 2)
                            .fill(fill(day: calendar.startOfDay(for: day), today: today,
                                       minutes: minutesByDay[calendar.startOfDay(for: day)] ?? 0,
                                       maxMinutes: maxMinutes))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
    }

    private func focusMinutesByDay(calendar: Calendar) -> [Date: Double] {
        var result: [Date: Double] = [:]
        for session in sessions where session.type == .work && session.status == .completed {
            let day = calendar.startOfDay(for: session.startTime)
            result[day, default: 0] += session.duration / 60
        }
        return result
    }

    private func fill(day: Date, today: Date, minutes: Double, maxMinutes: Double) -> Color {
        if day > today { return .clear }
        if minutes <= 0 { return Color(.systemGray5) }
        let intensity = min(1, 0.3 + (minutes / maxMinutes) * 0.7)
        return Color.orange.opacity(intensity)
    }
}
