import WidgetKit
import SwiftUI

// NOTE: This folder is the source for the FocusPulse widget extension. It is NOT part of the app
// target's synchronized group (so it never compiles into the app). Add it via Xcode as a new
// Widget Extension target; also add the app's `Shared/SharedTimerState.swift` to this target's
// membership (shared type) and enable the App Group `group.moe.sei.FocusPulse` on both targets.
// See README.md in this folder.

// MARK: - Bundle

@main
struct FocusPulseWidgets: WidgetBundle {
    var body: some Widget {
        FocusTimerWidget()
        FocusTimerLiveActivity()
    }
}

// MARK: - Timeline

struct TimerEntry: TimelineEntry {
    let date: Date
    let state: SharedTimerState
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), state: .idle)
    }
    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(TimerEntry(date: Date(), state: currentState()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        completion(Timeline(entries: [TimerEntry(date: Date(), state: currentState())], policy: .atEnd))
    }
    private func currentState() -> SharedTimerState {
        guard let data = AppGroup.defaults?.data(forKey: SharedTimerState.key),
              let state = try? JSONDecoder().decode(SharedTimerState.self, from: data)
        else { return .idle }
        return state
    }
}

// MARK: - Widget configuration

struct FocusTimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FocusTimerWidget", provider: TimerProvider()) { entry in
            FocusTimerWidgetView(state: entry.state)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Focus Timer")
        .description("Your current focus session at a glance.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular
        ])
    }
}

// MARK: - Views

struct FocusTimerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let state: SharedTimerState

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemMedium: medium
        default: small
        }
    }

    private var tint: Color { WidgetDisplay.color(state.sessionTypeRaw, running: state.isRunning) }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(WidgetDisplay.name(state), systemImage: WidgetDisplay.glyph(state))
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(tint)
            Spacer()
            countdown.font(.system(size: 30, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(tint.opacity(0.25), lineWidth: 8)
                Image(systemName: WidgetDisplay.glyph(state)).font(.title).foregroundStyle(tint)
            }
            .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(WidgetDisplay.name(state)).font(.headline).foregroundStyle(tint)
                countdown.font(.system(size: 40, weight: .bold, design: .rounded))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: WidgetDisplay.glyph(state)).font(.caption2)
                Text("\(state.remainingSeconds / 60)").font(.system(.headline, design: .rounded)).fontWeight(.bold)
            }
        }
    }

    private var rectangular: some View {
        HStack {
            Image(systemName: WidgetDisplay.glyph(state))
            VStack(alignment: .leading) {
                Text(WidgetDisplay.name(state)).font(.caption).fontWeight(.semibold)
                countdown.font(.system(.body, design: .rounded)).fontWeight(.bold)
            }
        }
    }

    @ViewBuilder private var countdown: some View {
        if state.isRunning, let end = state.expectedEndDate {
            Text(timerInterval: Date()...end, countsDown: true).monospacedDigit()
        } else {
            Text(String(format: "%02d:%02d", max(0, state.remainingSeconds) / 60, max(0, state.remainingSeconds) % 60))
                .monospacedDigit()
        }
    }
}

// MARK: - Display helpers

enum WidgetDisplay {
    static func color(_ raw: String, running: Bool) -> Color {
        guard running || raw != "" else { return .gray }
        switch raw {
        case "work": return .orange
        case "shortBreak": return .mint
        case "longBreak": return .teal
        default: return .gray
        }
    }
    static func name(_ state: SharedTimerState) -> String {
        if state.stateRaw == "idle" { return "Ready" }
        switch state.sessionTypeRaw {
        case "work": return "Focus"
        case "shortBreak": return "Short Break"
        case "longBreak": return "Long Break"
        default: return "Ready"
        }
    }
    static func glyph(_ state: SharedTimerState) -> String {
        switch state.sessionTypeRaw {
        case "work": return "brain.head.profile"
        case "shortBreak", "longBreak": return "cup.and.saucer.fill"
        default: return "timer"
        }
    }
}
