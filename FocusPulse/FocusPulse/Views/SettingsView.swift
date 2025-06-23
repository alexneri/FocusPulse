import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerEngine: TimerEngine
    @Environment(\.dismiss) private var dismiss
    

    
    var body: some View {
        NavigationView {
            Form {
                // Duration Settings
                durationSettingsSection
                
                // Audio & Haptic Settings
                audioSettingsSection
                
                // Behavior Settings
                behaviorSettingsSection
                
                // Data Management
                dataManagementSection
                
                // App Information
                appInfoSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Duration Settings Section
    
    private var durationSettingsSection: some View {
        Section {
            DurationSlider(
                title: "Work Session",
                value: $timerEngine.settings.workDuration,
                range: 300...3600, // 5 minutes to 1 hour
                step: 300 // 5-minute steps
            )
            
            DurationSlider(
                title: "Short Break",
                value: $timerEngine.settings.shortBreakDuration,
                range: 60...1800, // 1 minute to 30 minutes
                step: 60 // 1-minute steps
            )
            
            DurationSlider(
                title: "Long Break",
                value: $timerEngine.settings.longBreakDuration,
                range: 300...3600, // 5 minutes to 1 hour
                step: 300 // 5-minute steps
            )
            
            HStack {
                Text("Pomodoros until Long Break")
                Spacer()
                Picker("Long Break Interval", selection: $timerEngine.settings.longBreakInterval) {
                    ForEach(2...8, id: \.self) { interval in
                        Text("\(interval)").tag(interval)
                    }
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("Timer Durations")
        } footer: {
            Text("Customize the duration of work sessions and breaks to match your productivity rhythm.")
        }
    }
    
    // MARK: - Audio Settings Section
    
    private var audioSettingsSection: some View {
        Section {
            Toggle("Sound Effects", isOn: $timerEngine.settings.soundEnabled)
            
            Toggle("Haptic Feedback", isOn: $timerEngine.settings.hapticEnabled)
            
            Toggle("Music Integration", isOn: $timerEngine.settings.musicIntegrationEnabled)
        } header: {
            Text("Audio & Haptics")
        } footer: {
            Text("Enable audio feedback and haptic responses for timer events. Music integration allows automatic playback control during sessions.")
        }
    }
    
    // MARK: - Behavior Settings Section
    
    private var behaviorSettingsSection: some View {
        Section {
            Toggle("Auto-start Breaks", isOn: $timerEngine.settings.autoStartBreaks)
            
            Toggle("Auto-start Work Sessions", isOn: $timerEngine.settings.autoStartWork)
        } header: {
            Text("Auto-Start Behavior")
        } footer: {
            Text("Automatically start the next session when the current one completes. Useful for uninterrupted focus sessions.")
        }
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        Section {
            Button("Export Session Data") {
                // TODO: Implement data export
                print("Export data tapped")
            }
            .foregroundColor(.blue)
            
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .foregroundColor(.red)
        } header: {
            Text("Data Management")
        } footer: {
            Text("Export your productivity data or reset all settings to their default values.")
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text("1")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetToDefaults() {
        timerEngine.settings = TimerSettings()
    }
}

// MARK: - Duration Slider Component

struct DurationSlider: View {
    let title: String
    @Binding var value: TimeInterval
    let range: ClosedRange<TimeInterval>
    let step: TimeInterval
    
    private var displayValue: String {
        let minutes = Int(value) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(displayValue)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Slider(
                value: $value,
                in: range,
                step: step
            ) {
                Text(title)
            } minimumValueLabel: {
                Text(formatTime(range.lowerBound))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Text(formatTime(range.upperBound))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .accentColor(.blue)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    SettingsView(timerEngine: TimerEngine())
} 