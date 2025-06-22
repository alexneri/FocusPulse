import Foundation
import Combine
import SwiftUI
import AVFoundation

// MARK: - Timer Engine
@MainActor
class TimerEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var currentState: TimerState = .idle
    @Published var remainingTime: TimeInterval = 0
    @Published var currentSession: SessionType?
    @Published var cycleProgress: CycleProgress = CycleProgress(currentSessionIndex: 0, totalSessionsInCycle: 8, cyclesCompletedToday: 0)
    @Published var settings = TimerSettings()
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var sessionHistory: [CompletedSession] = []
    private var workSessionsCompleted = 0
    private var startTime: Date?
    
    // MARK: - Audio Properties
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Initialization
    init() {
        setupAudioSession()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Start or resume the timer
    func start() {
        switch currentState {
        case .idle:
            startNewSession()
        case .paused(let sessionType):
            resumeSession(sessionType)
        case .running, .completed:
            return // Already running or completed
        }
    }
    
    /// Pause the current timer
    func pause() {
        guard let sessionType = currentState.currentSessionType else { return }
        
        timer?.invalidate()
        timer = nil
        currentState = .paused(sessionType)
        
        playSound(.pause)
        triggerHapticFeedback(.light)
    }
    
    /// Stop and reset the timer
    func stop() {
        timer?.invalidate()
        timer = nil
        
        // Log interrupted session if one was running
        if let sessionType = currentState.currentSessionType,
           let startTime = startTime {
            let interruptedSession = CompletedSession(
                type: sessionType,
                startTime: startTime,
                endTime: Date(),
                actualDuration: sessionType.duration - remainingTime,
                wasCompleted: false
            )
            sessionHistory.append(interruptedSession)
        }
        
        currentState = .idle
        remainingTime = 0
        currentSession = nil
        startTime = nil
        
        playSound(.stop)
        triggerHapticFeedback(.medium)
    }
    
    /// Skip to the next session
    func skip() {
        completeCurrentSession(wasCompleted: false)
        startNextSession()
        
        playSound(.skip)
        triggerHapticFeedback(.light)
    }
    
    /// Reset timer to initial state
    func reset() {
        stop()
        workSessionsCompleted = 0
        cycleProgress = CycleProgress(currentSessionIndex: 0, totalSessionsInCycle: 8, cyclesCompletedToday: 0)
    }
    
    // MARK: - Private Methods
    
    private func startNewSession() {
        let sessionType = settings.createWorkSession()
        startSession(sessionType)
    }
    
    private func resumeSession(_ sessionType: SessionType) {
        currentState = .running(sessionType)
        currentSession = sessionType
        startTimer()
        
        playSound(.start)
        triggerHapticFeedback(.light)
    }
    
    private func startSession(_ sessionType: SessionType) {
        currentState = .running(sessionType)
        currentSession = sessionType
        remainingTime = sessionType.duration
        startTime = Date()
        
        startTimer()
        updateCycleProgress()
        
        playSound(.start)
        triggerHapticFeedback(.light)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }
    
    private func timerTick() {
        guard remainingTime > 0 else {
            completeCurrentSession(wasCompleted: true)
            return
        }
        
        remainingTime -= 1
    }
    
    private func completeCurrentSession(wasCompleted: Bool) {
        timer?.invalidate()
        timer = nil
        
        guard let sessionType = currentState.currentSessionType,
              let startTime = startTime else { return }
        
        // Log completed session
        let completedSession = CompletedSession(
            type: sessionType,
            startTime: startTime,
            endTime: Date(),
            actualDuration: sessionType.duration - (wasCompleted ? 0 : remainingTime),
            wasCompleted: wasCompleted
        )
        sessionHistory.append(completedSession)
        
        // Update work session counter
        if sessionType.isWorkSession && wasCompleted {
            workSessionsCompleted += 1
        }
        
        currentState = .completed(sessionType)
        
        // Play completion sound and haptic
        playSound(.complete)
        triggerHapticFeedback(.success)
        
        // Auto-start next session if enabled
        if shouldAutoStartNextSession() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.startNextSession()
            }
        }
    }
    
    private func startNextSession() {
        let nextSessionType = determineNextSessionType()
        startSession(nextSessionType)
    }
    
    private func determineNextSessionType() -> SessionType {
        guard let currentSessionType = currentState.currentSessionType else {
            return settings.createWorkSession()
        }
        
        switch currentSessionType {
        case .work:
            // Determine if it should be a long break
            if workSessionsCompleted % settings.longBreakInterval == 0 && workSessionsCompleted > 0 {
                return settings.createLongBreakSession()
            } else {
                return settings.createShortBreakSession()
            }
        case .shortBreak, .longBreak:
            return settings.createWorkSession()
        }
    }
    
    private func shouldAutoStartNextSession() -> Bool {
        guard let currentSessionType = currentState.currentSessionType else { return false }
        
        switch currentSessionType {
        case .work:
            return settings.autoStartBreaks
        case .shortBreak, .longBreak:
            return settings.autoStartWork
        }
    }
    
    private func updateCycleProgress() {
        let totalSessions = settings.longBreakInterval * 2 // Work + break sessions
        let currentIndex = (workSessionsCompleted * 2) % totalSessions
        
        cycleProgress = CycleProgress(
            currentSessionIndex: currentIndex,
            totalSessionsInCycle: totalSessions,
            cyclesCompletedToday: workSessionsCompleted / settings.longBreakInterval
        )
    }
    
    // MARK: - Audio & Haptic Feedback
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func playSound(_ soundType: SoundType) {
        guard settings.soundEnabled else { return }
        
        // In a real implementation, you would load actual sound files
        // For now, we'll use system sounds or create placeholder sounds
        print("Playing sound: \(soundType)")
    }
    
    private func triggerHapticFeedback(_ type: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settings.hapticEnabled else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: type)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Computed Properties
    
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        guard let sessionType = currentState.currentSessionType else { return 0 }
        let elapsed = sessionType.duration - remainingTime
        return elapsed / sessionType.duration
    }
    
    var canStart: Bool {
        switch currentState {
        case .idle, .paused:
            return true
        default:
            return false
        }
    }
    
    var canPause: Bool {
        currentState.isRunning
    }
    
    var canStop: Bool {
        switch currentState {
        case .running, .paused:
            return true
        default:
            return false
        }
    }
    
    var canSkip: Bool {
        switch currentState {
        case .running, .paused:
            return true
        default:
            return false
        }
    }
}

// MARK: - Supporting Types

enum SoundType {
    case start
    case pause
    case stop
    case complete
    case skip
}

// MARK: - Extensions

extension UIImpactFeedbackGenerator.FeedbackStyle {
    static let success = UIImpactFeedbackGenerator.FeedbackStyle.heavy
} 