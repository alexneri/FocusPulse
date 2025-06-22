import Foundation
import SwiftUI

// MARK: - Timer State Management
enum TimerState: Equatable {
    case idle
    case running(SessionType)
    case paused(SessionType)
    case completed(SessionType)
    
    var isRunning: Bool {
        switch self {
        case .running:
            return true
        default:
            return false
        }
    }
    
    var isPaused: Bool {
        switch self {
        case .paused:
            return true
        default:
            return false
        }
    }
    
    var currentSessionType: SessionType? {
        switch self {
        case .running(let type), .paused(let type), .completed(let type):
            return type
        case .idle:
            return nil
        }
    }
}

// MARK: - Session Types
enum SessionType: Equatable, CaseIterable {
    case work(duration: TimeInterval)
    case shortBreak(duration: TimeInterval)
    case longBreak(duration: TimeInterval)
    
    var duration: TimeInterval {
        switch self {
        case .work(let duration), .shortBreak(let duration), .longBreak(let duration):
            return duration
        }
    }
    
    var displayName: String {
        switch self {
        case .work:
            return "Work Session"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
    
    var color: Color {
        switch self {
        case .work:
            return .blue
        case .shortBreak:
            return .orange
        case .longBreak:
            return .green
        }
    }
    
    var isWorkSession: Bool {
        switch self {
        case .work:
            return true
        default:
            return false
        }
    }
}

// MARK: - Cycle Progress
struct CycleProgress {
    let currentSessionIndex: Int
    let totalSessionsInCycle: Int
    let cyclesCompletedToday: Int
    
    var progressPercentage: Double {
        guard totalSessionsInCycle > 0 else { return 0 }
        return Double(currentSessionIndex) / Double(totalSessionsInCycle)
    }
}

// MARK: - Completed Session
struct CompletedSession: Identifiable {
    let id = UUID()
    let type: SessionType
    let startTime: Date
    let endTime: Date
    let actualDuration: TimeInterval
    let wasCompleted: Bool
    
    var displayDuration: String {
        let minutes = Int(actualDuration) / 60
        let seconds = Int(actualDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Settings Model
struct TimerSettings {
    var workDuration: TimeInterval = 25 * 60 // 25 minutes
    var shortBreakDuration: TimeInterval = 5 * 60 // 5 minutes
    var longBreakDuration: TimeInterval = 15 * 60 // 15 minutes
    var longBreakInterval: Int = 4 // Every 4 work sessions
    var soundEnabled: Bool = true
    var hapticEnabled: Bool = true
    var musicIntegrationEnabled: Bool = false
    var autoStartBreaks: Bool = false
    var autoStartWork: Bool = false
    
    // Create session types with current durations
    func createWorkSession() -> SessionType {
        return .work(duration: workDuration)
    }
    
    func createShortBreakSession() -> SessionType {
        return .shortBreak(duration: shortBreakDuration)
    }
    
    func createLongBreakSession() -> SessionType {
        return .longBreak(duration: longBreakDuration)
    }
} 