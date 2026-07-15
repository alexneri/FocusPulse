import Foundation

/// App Group used to share the current timer state between the app and its widget / Live Activity
/// extension (Story 5.1). The widget process cannot read the in-memory `TimerEngine`, so the app
/// writes a lightweight snapshot here.
enum AppGroup {
    static let identifier = "group.moe.sei.FocusPulse"
    static var defaults: UserDefaults? { UserDefaults(suiteName: identifier) }
}

/// The lightweight, App-Group-shared snapshot of the current session. Widgets read this and drive
/// their own countdown from `expectedEndDate` (so they don't need per-second updates).
struct SharedTimerState: Codable, Equatable {
    var stateRaw: String
    var sessionTypeRaw: String
    var remainingSeconds: Int
    var expectedEndDate: Date?
    var isRunning: Bool

    static let key = "sharedTimerState"

    static let idle = SharedTimerState(
        stateRaw: "idle", sessionTypeRaw: "work", remainingSeconds: 25 * 60,
        expectedEndDate: nil, isRunning: false)
}
