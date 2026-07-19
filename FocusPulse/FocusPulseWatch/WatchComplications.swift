import WidgetKit
import SwiftUI
import FocusPulseCore

// NOTE: FocusPulse Apple Watch complications (Story 7.5). Ship these in a Widget Extension embedded
// in the watch app (a separate target). They read the App-Group `SharedTimerState` the watch app
// writes and drive their own countdown from `expectedEndDate` — no per-second updates. Full-color
// uses the session tint; the system renders tinted/accented faces from luminance automatically.
// Add `Shared/SharedTimerState.swift` to this extension's target membership. See README.md.

struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let state: SharedTimerState
}

struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: Date(), state: .idle)
    }
    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        completion(WatchComplicationEntry(date: Date(), state: current()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        // Refresh at session end; while running, the countdown text advances on its own.
        let entry = WatchComplicationEntry(date: Date(), state: current())
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
    private func current() -> SharedTimerState {
        guard let data = AppGroup.defaults?.data(forKey: SharedTimerState.key),
              let state = try? JSONDecoder().decode(SharedTimerState.self, from: data) else { return .idle }
        return state
    }
}

@main
struct FocusPulseWatchComplications: WidgetBundle {
    var body: some Widget { FocusComplication() }
}

struct FocusComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FocusPulseWatchComplication", provider: WatchComplicationProvider()) { entry in
            ComplicationView(state: entry.state)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("Focus")
        .description("Your focus session at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let state: SharedTimerState

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryCorner: corner
        case .accessoryInline: inline
        default: rectangular
        }
    }

    private var running: Bool { state.isRunning }
    private var minutes: Int { max(0, state.remainingSeconds) / 60 }
    private var glyph: String { CDisplay.glyph(state) }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: glyph).font(.caption2)
                Text(running ? "\(minutes)" : "–").font(.system(.headline, design: .rounded)).fontWeight(.bold)
            }
        }
    }
    private var corner: some View {
        Image(systemName: glyph)
            .font(.title2)
            .widgetLabel(running ? "\(minutes)m \(CDisplay.name(state))" : "Ready")
    }
    private var inline: some View {
        Label(
            running ? "\(CDisplay.name(state)) \(CDisplay.mmss(state.remainingSeconds))" : "FocusPulse · Ready",
            systemImage: glyph
        )
    }
    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: glyph).font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(running ? CDisplay.name(state) : "FocusPulse").font(.headline)
                Text(running ? "\(CDisplay.mmss(state.remainingSeconds)) remaining" : "Ready · tap to focus")
                    .font(.caption)
            }
        }
    }
}

/// Local display helpers for the complications target (kept self-contained so this file needs no
/// membership beyond `SharedTimerState`).
private enum CDisplay {
    static func name(_ s: SharedTimerState) -> String {
        if s.stateRaw == "idle" { return "Ready" }
        switch s.sessionTypeRaw {
        case "work": return "Focus"
        case "shortBreak": return "Short Break"
        case "longBreak": return "Long Break"
        default: return "Ready"
        }
    }
    static func glyph(_ s: SharedTimerState) -> String {
        switch s.sessionTypeRaw {
        case "work": return "target"
        case "shortBreak": return "cup.and.saucer.fill"
        case "longBreak": return "leaf.fill"
        default: return "timer"
        }
    }
    static func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
