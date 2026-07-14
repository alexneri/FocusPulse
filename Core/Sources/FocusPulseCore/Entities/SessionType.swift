import Foundation

/// The three kinds of Pomodoro session. Semantic colours (Work = orange, Short Break = mint,
/// Long Break = teal) are supplied by the active Visual Theme in the presentation layer.
public enum SessionType: String, Codable, Sendable, CaseIterable {
    case work
    case shortBreak
    case longBreak

    /// `true` for either break kind.
    public var isBreak: Bool { self != .work }
}
