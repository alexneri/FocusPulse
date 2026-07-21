import SwiftUI
import WatchKit
import PulseArcCore

// NOTE: PulseArc Apple Watch source — NOT compiled into the iOS app target. See README.md.

/// The PulseArc Apple Watch timer face (Story 7.2): one hero element (ring + countdown), two
/// controls, glanceable in ~1 second. Renders from `model.display` and the active Visual Theme.
///
/// Honors the per-theme **Always-On** collapse rule (architecture §8.2, merged in ideahub #32):
/// under `isLuminanceReduced` the canvas drops to near-black, the ring dims to ~30% and its pulse
/// glow is removed — no bright fills, no OLED burn-in. The glow is likewise dropped under Reduce
/// Motion.
struct WatchTimerView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var model: WatchTimerViewModel
    @Environment(\.isLuminanceReduced) private var isAlwaysOn
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var crown: Double = 0

    private var snap: TimerSnapshot { model.display }
    private var tint: Color { theme.activeTheme.sessionColor(snap.sessionType) }
    private var isMono: Bool { theme.activeTheme.id == "terminal" }

    var body: some View {
        ZStack {
            (isAlwaysOn ? Color.black : theme.activeTheme.canvas).ignoresSafeArea()
            VStack(spacing: 5) {
                chip
                ring
                if isAlwaysOn {
                    Spacer().frame(height: 2)
                } else {
                    controls
                }
                if snap.isActive { cycleDots }
            }
            .padding(.horizontal, 6)
        }
        .focusable(true)
        .digitalCrownRotation($crown, from: 0, through: 3, by: 1, sensitivity: .low,
                              isContinuous: false, isHapticFeedbackEnabled: true)
        .overlay(alignment: .bottom) { crownPeek }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(WatchDisplay.voiceOver(snap))
    }

    private var chip: some View {
        Label(WatchDisplay.name(snap), systemImage: WatchDisplay.glyph(snap))
            .labelStyle(.titleAndIcon)
            .font(.system(.caption2, design: isMono ? .monospaced : .rounded).weight(.semibold))
            .foregroundStyle(isAlwaysOn ? tint.opacity(0.7) : tint)
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(theme.activeTheme.ink.opacity(0.12), lineWidth: isAlwaysOn ? 5 : 9)
            Circle()
                .trim(from: 0, to: CGFloat(model.progress))
                .stroke(tint.opacity(isAlwaysOn ? 0.3 : 1),
                        style: StrokeStyle(lineWidth: isAlwaysOn ? 5 : 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: pulseGlow, radius: 6)
                .animation(.easeInOut(duration: 0.3), value: model.progress)
            countdown
        }
        .padding(6)
    }

    /// The pulse glow — dropped in Always-On, under Reduce Motion, and when idle.
    private var pulseGlow: Color {
        (isAlwaysOn || reduceMotion || !snap.isActive) ? .clear : tint.opacity(0.6)
    }

    @ViewBuilder private var countdown: some View {
        Group {
            if snap.state == .running, let end = snap.expectedEndDate {
                Text(timerInterval: Date()...end, countsDown: true)
            } else {
                Text(WatchDisplay.mmss(snap.remainingSeconds))
            }
        }
        .font(.system(size: 38, weight: .semibold, design: isMono ? .monospaced : .rounded))
        .monospacedDigit()
        .minimumScaleFactor(0.5)
        .foregroundStyle(isAlwaysOn ? theme.activeTheme.ink.opacity(0.85) : theme.activeTheme.ink)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button(action: model.primaryTapped) {
                Image(systemName: snap.state == .running ? "pause.fill" : "play.fill")
            }
            .handGestureShortcut(.primaryAction)     // Apple Watch Double Tap (watchOS 11)
            .accessibilityLabel(snap.state == .running ? "Pause" : (snap.isActive ? "Resume" : "Start"))

            if snap.isActive {
                Button(action: model.skipTapped) { Image(systemName: "forward.fill") }
                    .accessibilityLabel("Skip")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .controlSize(.large)
        .font(.title3)
    }

    private var cycleDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < model.cycleFilled ? tint : theme.activeTheme.ink.opacity(0.25))
                    .frame(width: 5, height: 5)
            }
        }
        .accessibilityHidden(true)
    }

    /// Digital Crown → a non-destructive, read-only peek at upcoming sessions. Never edits the cycle.
    @ViewBuilder private var crownPeek: some View {
        if crown >= 1, !isAlwaysOn {
            Text(WatchDisplay.upcoming(step: Int(crown)))
                .font(.system(.caption2, design: isMono ? .monospaced : .rounded))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.opacity)
        }
    }
}

// MARK: - Display helpers

enum WatchDisplay {
    static func name(_ s: TimerSnapshot) -> String {
        guard s.state != .idle else { return "Ready" }
        switch s.sessionType {
        case .work: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
    static func glyph(_ s: TimerSnapshot) -> String {
        switch s.sessionType {
        case .work: return "target"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "leaf.fill"
        }
    }
    static func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
    static func voiceOver(_ s: TimerSnapshot) -> String {
        s.state == .idle ? "Ready to focus" : "\(name(s)), \(mmss(s.remainingSeconds)) remaining"
    }
    /// Read-only preview of the cycle order (Work → Short Break → … → Long Break).
    static func upcoming(step: Int) -> String {
        let sequence = ["Focus · 25:00", "Short break · 5:00", "Focus · 25:00", "Long break · 15:00"]
        return sequence[min(max(0, step), sequence.count - 1)]
    }
}
