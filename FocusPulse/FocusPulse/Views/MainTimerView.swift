import SwiftUI

struct MainTimerView: View {
    @StateObject private var timerEngine = TimerEngine()
    @State private var showingSettings = false
    @State private var showingStatistics = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Timer Section
                    timerSection
                    
                    Spacer()
                    
                    // Control Buttons
                    controlButtonsSection
                    
                    // Cycle Progress
                    cycleProgressSection
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        statisticsButton
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        settingsButton
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(timerEngine: timerEngine)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(timerEngine: timerEngine)
        }
    }
    
    // MARK: - Timer Section
    
    private var timerSection: some View {
        VStack(spacing: 16) {
            // Circular Progress with Time Display
            ZStack {
                CircularProgressView(
                    progress: timerEngine.progressPercentage,
                    sessionType: timerEngine.currentSession,
                    isRunning: timerEngine.currentState.isRunning
                )
                
                VStack(spacing: 8) {
                    // Time Display
                    Text(timerEngine.formattedRemainingTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    // Session Type
                    if let sessionType = timerEngine.currentSession {
                        Text(sessionType.displayName)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(sessionType.color)
                    } else {
                        Text("Ready to Focus")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Control Buttons Section
    
    private var controlButtonsSection: some View {
        HStack(spacing: 24) {
            // Stop Button
            if timerEngine.canStop {
                ControlButton(
                    systemName: "stop.fill",
                    color: .red,
                    action: timerEngine.stop
                )
                .accessibilityLabel("Stop timer")
            }
            
            // Primary Action Button (Play/Pause)
            ControlButton(
                systemName: primaryButtonSystemName,
                color: .blue,
                isLarge: true,
                action: primaryButtonAction
            )
            .accessibilityLabel(primaryButtonAccessibilityLabel)
            
            // Skip Button
            if timerEngine.canSkip {
                ControlButton(
                    systemName: "forward.fill",
                    color: .orange,
                    action: timerEngine.skip
                )
                .accessibilityLabel("Skip to next session")
            }
        }
    }
    
    // MARK: - Cycle Progress Section
    
    private var cycleProgressSection: some View {
        VStack(spacing: 12) {
            Text("Cycle Progress")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(0..<timerEngine.cycleProgress.totalSessionsInCycle, id: \.self) { index in
                    Circle()
                        .fill(cycleProgressColor(for: index))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text("\(timerEngine.cycleProgress.cyclesCompletedToday) cycles completed today")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var statisticsButton: some View {
        Button(action: { showingStatistics = true }) {
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Statistics")
    }
    
    private var settingsButton: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Settings")
    }
    
    // MARK: - Computed Properties
    
    private var primaryButtonSystemName: String {
        switch timerEngine.currentState {
        case .idle, .completed:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .paused:
            return "play.fill"
        }
    }
    
    private var primaryButtonAction: () -> Void {
        switch timerEngine.currentState {
        case .idle, .paused, .completed:
            return timerEngine.start
        case .running:
            return timerEngine.pause
        }
    }
    
    private var primaryButtonAccessibilityLabel: String {
        switch timerEngine.currentState {
        case .idle, .completed:
            return "Start timer"
        case .running:
            return "Pause timer"
        case .paused:
            return "Resume timer"
        }
    }
    
    private func cycleProgressColor(for index: Int) -> Color {
        if index < timerEngine.cycleProgress.currentSessionIndex {
            return .green
        } else if index == timerEngine.cycleProgress.currentSessionIndex {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Control Button Component

struct ControlButton: View {
    let systemName: String
    let color: Color
    let isLarge: Bool
    let action: () -> Void
    
    init(systemName: String, color: Color, isLarge: Bool = false, action: @escaping () -> Void) {
        self.systemName = systemName
        self.color = color
        self.isLarge = isLarge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isLarge ? 32 : 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: isLarge ? 80 : 60, height: isLarge ? 80 : 60)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @State private var isPressed = false
}

// MARK: - Preview

#Preview {
    MainTimerView()
} 