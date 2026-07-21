import Foundation

/// The state machine for the timer. Transitions are enforced by `TimerEngine`
/// (e.g. `.idle` can never go directly to `.paused`).
public enum TimerState: String, Codable, Sendable {
    case idle
    case running
    case paused
    case completed
}
