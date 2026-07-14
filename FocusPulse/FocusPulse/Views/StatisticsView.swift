import SwiftUI

struct StatisticsView: View {
    @ObservedObject var timerEngine: TimerEngine
    @State private var selectedPeriod: TimePeriod = .daily
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Period Selector
                    timePeriodSelector
                    
                    // Key Metrics Cards
                    keyMetricsSection
                    
                    // Chart Visualization
                    chartSection
                    
                    // Session History
                    sessionHistorySection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    shareButton
                }
            }
        }
    }
    
    // MARK: - Time Period Selector
    
    private var timePeriodSelector: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Total Focus Time",
                value: formatFocusTime(mockStats.totalFocusTime),
                icon: "clock.fill",
                color: .blue
            )
            
            MetricCard(
                title: "Sessions Completed",
                value: "\(mockStats.completedSessions)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            MetricCard(
                title: "Focus Streak",
                value: "\(mockStats.focusStreak) days",
                icon: "flame.fill",
                color: .orange
            )
            
            MetricCard(
                title: "Completion Rate",
                value: "\(Int(mockStats.completionRate * 100))%",
                icon: "chart.bar.fill",
                color: .purple
            )
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for chart - In a real app, you'd use Swift Charts
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text("Focus Time Chart")
                            .font(.headline)
                        Text("Chart visualization would go here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    // MARK: - Session History Section
    
    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("View All") {
                    // TODO: Navigate to full session history
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(mockSessions) { session in
                    SessionHistoryRow(session: session)
                }
            }
        }
    }
    
    // MARK: - Share Button
    
    private var shareButton: some View {
        Button(action: shareStats) {
            Image(systemName: "square.and.arrow.up")
                .font(.title2)
        }
        .accessibilityLabel("Share statistics")
    }
    
    // MARK: - Helper Methods
    
    private func formatFocusTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func shareStats() {
        // TODO: Implement statistics sharing
        print("Share statistics tapped")
    }
    
    // MARK: - Mock Data (Replace with real data)
    
    private var mockStats: DailyStatistics {
        DailyStatistics(
            totalFocusTime: 7200, // 2 hours
            completedSessions: 8,
            focusStreak: 5,
            completionRate: 0.85
        )
    }
    
    private var mockSessions: [SessionHistory] {
        [
            SessionHistory(
                type: .work(duration: 1500),
                startTime: Date().addingTimeInterval(-3600),
                duration: 1500,
                wasCompleted: true
            ),
            SessionHistory(
                type: .shortBreak(duration: 300),
                startTime: Date().addingTimeInterval(-5100),
                duration: 300,
                wasCompleted: true
            ),
            SessionHistory(
                type: .work(duration: 1500),
                startTime: Date().addingTimeInterval(-6900),
                duration: 1200,
                wasCompleted: false
            )
        ]
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SessionHistoryRow: View {
    let session: SessionHistory
    
    var body: some View {
        HStack(spacing: 12) {
            // Session Type Icon
            Circle()
                .fill(session.type.color)
                .frame(width: 12, height: 12)
            
            // Session Info
            VStack(alignment: .leading, spacing: 2) {
                Text(session.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatTime(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Duration and Status
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(session.wasCompleted ? .green : .red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes)m"
    }
}

// MARK: - Supporting Types

enum TimePeriod: CaseIterable {
    case daily, weekly, monthly
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct DailyStatistics {
    let totalFocusTime: TimeInterval
    let completedSessions: Int
    let focusStreak: Int
    let completionRate: Double
}

struct SessionHistory: Identifiable {
    let id = UUID()
    let type: SessionType
    let startTime: Date
    let duration: TimeInterval
    let wasCompleted: Bool
}

// MARK: - Preview

#Preview {
    StatisticsView(timerEngine: TimerEngine())
} 