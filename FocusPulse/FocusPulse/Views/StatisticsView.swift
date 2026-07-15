import SwiftUI
import Charts
import FocusPulseCore

struct StatisticsView: View {
    @ObservedObject var timerEngine: TimerEngine
    @State private var sessions: [FocusSession] = []
    @Environment(\.dismiss) private var dismiss

    private let repository: SessionRepository
    private let statsEngine = StatisticsEngine()

    init(timerEngine: TimerEngine, repository: SessionRepository = CoreDataSessionRepository()) {
        self.timerEngine = timerEngine
        self.repository = repository
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    keyMetricsSection
                    chartSection
                    sessionHistorySection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "chart.bar",
                        description: Text("Finish a focus session and your stats will show up here.")
                    )
                }
            }
        }
        .task { await loadSessions() }
    }

    // MARK: - Key Metrics

    private var keyMetricsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCard(title: "Total Focus Time", value: formatFocusTime(statsEngine.totalFocusTime(sessions)),
                       icon: "clock.fill", color: .orange)
            MetricCard(title: "Sessions Completed", value: "\(completedWorkCount)",
                       icon: "checkmark.circle.fill", color: .mint)
            MetricCard(title: "Focus Streak", value: "\(statsEngine.currentStreak(sessions, asOf: Date())) days",
                       icon: "flame.fill", color: .pink)
            MetricCard(title: "Best Focus Time", value: bestFocusHourLabel,
                       icon: "sun.max.fill", color: .teal)
        }
    }

    // MARK: - Chart (Epic 3.3)

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)

            Chart(weeklyChartData) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(.orange.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .frame(height: 200)
        }
    }

    // MARK: - Session History

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVStack(spacing: 12) {
                ForEach(sessions.prefix(12)) { session in
                    FocusSessionRow(session: session)
                }
            }
        }
    }

    // MARK: - Derived values

    private var completedWorkCount: Int {
        sessions.filter { $0.type == .work && $0.status == .completed }.count
    }

    private var bestFocusHourLabel: String {
        guard let hour = statsEngine.bestFocusHour(sessions) else { return "—" }
        var comps = DateComponents(); comps.hour = hour
        let date = Calendar.current.date(from: comps) ?? Date()
        let formatter = DateFormatter(); formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    /// Focus minutes for each of the last 7 days (zero-filled).
    private var weeklyChartData: [DayFocus] {
        let calendar = Calendar.current
        let byDay = Dictionary(
            statsEngine.dailyStats(sessions).map { (calendar.startOfDay(for: $0.date), $0.totalFocusTime) },
            uniquingKeysWith: { a, _ in a }
        )
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset -> DayFocus? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayFocus(date: day, minutes: (byDay[day] ?? 0) / 60)
        }
    }

    private func loadSessions() async {
        sessions = (try? await repository.allSessions()) ?? []
    }

    private func formatFocusTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

// MARK: - Chart Data

struct DayFocus: Identifiable {
    let date: Date
    let minutes: Double
    var id: Date { date }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.title).fontWeight(.bold).foregroundColor(.primary)
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Session Row

struct FocusSessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline).fontWeight(.medium)
                Text(session.startTime, style: .time).font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(session.duration) / 60)m").font(.subheadline).fontWeight(.medium)
                Image(systemName: session.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(session.status == .completed ? .green : .secondary)
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray5), lineWidth: 1))
    }

    private var color: Color {
        switch session.type {
        case .work: return .orange
        case .shortBreak: return .mint
        case .longBreak: return .teal
        }
    }

    private var name: String {
        switch session.type {
        case .work: return "Work Session"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}
