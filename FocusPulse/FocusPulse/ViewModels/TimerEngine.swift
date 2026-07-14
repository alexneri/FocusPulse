import Foundation
import Combine
import SwiftUI
import AVFoundation
import FocusPulseCore

// MARK: - Timer Engine (presentation adapter)

/// Presentation-layer adapter over the verified `FocusPulseCore.TimerEngine`.
///
/// The views keep the same interface they already use, but every bit of timing and
/// state-machine logic is delegated to the drift-safe core engine — which derives the
/// remaining time from a `Date` diff instead of `remainingTime -= 1`, so it stays accurate
/// when the run loop stalls or the app is backgrounded (Story 1.2 / 1.4).
@MainActor
class TimerEngine: ObservableObject {
    /// App-facing settings, bound by `SettingsView`. Any change is applied to the core engine.
    @Published var settings: TimerSettings {
        didSet { applySettings() }
    }

    /// The verified domain engine — the single source of truth for timer state.
    let core: FocusPulseCore.TimerEngine

    private var cancellables = Set<AnyCancellable>()

    init() {
        let initial = TimerSettings()
        self.settings = initial
        self.core = FocusPulseCore.TimerEngine(configuration: TimerEngine.configuration(from: initial))
        setupAudioSession()

        // Re-render whenever the core changes (it self-ticks once per second).
        core.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Session finished (reached zero or skipped) -> feedback (persistence lands in Epic 2).
        core.onSessionCompleted = { [weak self] _, _, _ in
            self?.playSound(.complete)
            self?.triggerHapticFeedback(.success)
        }
    }

    // MARK: - App-facing state (mapped from the core)

    var currentState: TimerState {
        switch core.state {
        case .idle: return .idle
        case .running: return .running(appSession)
        case .paused: return .paused(appSession)
        case .completed: return .completed(appSession)
        }
    }

    var currentSession: SessionType? {
        core.state == .idle ? nil : appSession
    }

    private var appSession: SessionType {
        switch core.sessionType {
        case .work: return .work(duration: settings.workDuration)
        case .shortBreak: return .shortBreak(duration: settings.shortBreakDuration)
        case .longBreak: return .longBreak(duration: settings.longBreakDuration)
        }
    }

    var remainingTime: TimeInterval { TimeInterval(core.remainingSeconds) }

    var formattedRemainingTime: String {
        let total = max(0, core.remainingSeconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var progressPercentage: Double {
        let total = core.configuration.duration(for: core.sessionType)
        guard total > 0 else { return 0 }
        return min(1, max(0, (total - remainingTime) / total))
    }

    var cycleProgress: CycleProgress {
        let total = settings.longBreakInterval * 2
        let index = total > 0 ? (core.completedWorkSessions * 2) % total : 0
        return CycleProgress(
            currentSessionIndex: index,
            totalSessionsInCycle: total,
            cyclesCompletedToday: core.completedWorkSessions / max(1, settings.longBreakInterval)
        )
    }

    var canStart: Bool { core.state == .idle || core.state == .paused }
    var canPause: Bool { core.state == .running }
    var canStop: Bool { core.state == .running || core.state == .paused }
    var canSkip: Bool { core.state == .running || core.state == .paused }

    // MARK: - Controls (delegate to the core, add feedback)

    func start() {
        core.togglePlayPause() // idle -> start; paused/completed -> resume/start
        playSound(.start)
        triggerHapticFeedback(.light)
    }

    func pause() {
        core.pause()
        playSound(.pause)
        triggerHapticFeedback(.light)
    }

    func stop() {
        core.stop()
        playSound(.stop)
        triggerHapticFeedback(.medium)
    }

    func skip() {
        core.skip()
        playSound(.skip)
        triggerHapticFeedback(.light)
    }

    func reset() { stop() }

    // MARK: - Settings

    private func applySettings() {
        core.updateConfiguration(TimerEngine.configuration(from: settings))
    }

    private static func configuration(from settings: TimerSettings) -> TimerConfiguration {
        TimerConfiguration(
            workMinutes: Int((settings.workDuration / 60).rounded()),
            shortBreakMinutes: Int((settings.shortBreakDuration / 60).rounded()),
            longBreakMinutes: Int((settings.longBreakDuration / 60).rounded()),
            longBreakInterval: settings.longBreakInterval
        )
    }

    // MARK: - Audio & Haptic Feedback

    private func setupAudioSession() {
        do {
            // `.ambient` respects the silent switch (design-spec §; Story 1.5).
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func playSound(_ soundType: SoundType) {
        guard settings.soundEnabled else { return }
        // Placeholder until bundled .caf assets land (Story 1.5).
        print("Playing sound: \(soundType)")
    }

    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settings.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Supporting Types

enum SoundType {
    case start, pause, stop, complete, skip
}

extension UIImpactFeedbackGenerator.FeedbackStyle {
    static let success = UIImpactFeedbackGenerator.FeedbackStyle.heavy
}
