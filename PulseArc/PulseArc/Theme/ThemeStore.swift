import SwiftUI
import Combine

/// Light/dark appearance, orthogonal to the visual theme.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var name: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Free accent choices available within the Refined theme.
enum AccentChoice: String, CaseIterable, Identifiable {
    case orange, blue, graphite
    var id: String { rawValue }
    var name: String {
        switch self {
        case .orange: return "Focus Orange"
        case .blue: return "Deep Blue"
        case .graphite: return "Graphite"
        }
    }
    var color: Color {
        switch self {
        case .orange: return Color(hex: "FF9D3B")
        case .blue: return Color(hex: "3C7DD6")
        case .graphite: return Color(hex: "6E7075")
        }
    }
}

/// Owns theme selection + appearance + accent, persists them, and publishes the active theme.
/// Injected into the environment; every view reads its colours from `activeTheme`.
@MainActor
final class ThemeStore: ObservableObject {
    static let bundled: [VisualTheme] = [.refined, .ambient, .matcha, .terminal]

    @Published var selectedThemeID: String {
        didSet { defaults.set(selectedThemeID, forKey: Keys.theme) }
    }
    @Published var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    @Published var accentChoice: AccentChoice {
        didSet { defaults.set(accentChoice.rawValue, forKey: Keys.accent) }
    }

    private let defaults: UserDefaults
    private enum Keys {
        static let theme = "pulsearc.theme"
        static let appearance = "pulsearc.appearance"
        static let accent = "pulsearc.accent"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedThemeID = defaults.string(forKey: Keys.theme) ?? VisualTheme.refined.id
        appearance = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        accentChoice = AccentChoice(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .orange
    }

    var activeTheme: VisualTheme {
        Self.bundled.first { $0.id == selectedThemeID } ?? .refined
    }

    /// The accent to tint the app with: the user's choice within Refined, else the theme's own.
    var activeAccent: Color {
        activeTheme.supportsAccentChoice ? accentChoice.color : activeTheme.accent
    }

    func select(_ theme: VisualTheme) {
        selectedThemeID = theme.id
    }
}
