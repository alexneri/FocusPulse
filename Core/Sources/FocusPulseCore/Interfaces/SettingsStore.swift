import Foundation

/// The subset of user preferences the Domain relies on. The app layer implements this over
/// `UserDefaults` and exposes it as an `ObservableObject`; the Domain only sees this interface.
@MainActor
public protocol SettingsStore: AnyObject {
    var configuration: TimerConfiguration { get set }
    var autoStartBreaks: Bool { get set }
    var autoStartWork: Bool { get set }
    var soundEnabled: Bool { get set }
    var hapticsEnabled: Bool { get set }
}
