import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity attributes (Story 5.4). The app starts/updates/ends the activity from
/// `TimerEngine`; the widget extension renders it on the Lock Screen and in the Dynamic Island.
struct FocusTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var sessionTypeRaw: String
        var stateRaw: String
        var endDate: Date
    }
    var sessionLabel: String
}

struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            // Lock Screen / banner
            HStack {
                Label(name(context.state.sessionTypeRaw), systemImage: glyph(context.state.sessionTypeRaw))
                    .foregroundStyle(tint(context.state.sessionTypeRaw))
                    .font(.headline)
                Spacer()
                Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                    .monospacedDigit().font(.title2).fontWeight(.bold)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.35))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(name(context.state.sessionTypeRaw), systemImage: glyph(context.state.sessionTypeRaw))
                        .foregroundStyle(tint(context.state.sessionTypeRaw))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .monospacedDigit().frame(width: 64)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Link(destination: URL(string: "focuspulse://pause")!) {
                            Label("Pause", systemImage: "pause.fill")
                        }
                        Spacer()
                        Link(destination: URL(string: "focuspulse://skip")!) {
                            Label("Skip", systemImage: "forward.fill")
                        }
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Image(systemName: glyph(context.state.sessionTypeRaw))
                    .foregroundStyle(tint(context.state.sessionTypeRaw))
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                    .monospacedDigit().frame(width: 46)
            } minimal: {
                Image(systemName: glyph(context.state.sessionTypeRaw))
                    .foregroundStyle(tint(context.state.sessionTypeRaw))
            }
            .widgetURL(URL(string: "focuspulse://open"))
        }
    }

    private func tint(_ raw: String) -> Color {
        switch raw {
        case "work": return .orange
        case "shortBreak": return .mint
        case "longBreak": return .teal
        default: return .gray
        }
    }
    private func name(_ raw: String) -> String {
        switch raw {
        case "work": return "Focus"
        case "shortBreak": return "Short Break"
        case "longBreak": return "Long Break"
        default: return "Focus"
        }
    }
    private func glyph(_ raw: String) -> String {
        raw == "work" ? "brain.head.profile" : "cup.and.saucer.fill"
    }
}
