import SwiftUI
import FocusPulseCore

/// A complete visual theme (token set). The app renders from the active theme's tokens so it can
/// be re-skinned without touching view code. Tokens resolve light/dark automatically.
/// See `docs/design-spec.md` §2.1.1 for the token tables.
struct VisualTheme: Identifiable, Equatable {
    enum Tier: String {
        case free = "Free"
        case pro = "Pro"
    }

    let id: String
    let name: String
    let tier: Tier
    let canvas: Color
    let surface: Color
    let ink: Color
    let accent: Color
    let work: Color
    let shortBreak: Color
    let longBreak: Color
    /// Only the Refined theme lets the user pick an accent.
    let supportsAccentChoice: Bool

    func sessionColor(_ type: FocusPulseCore.SessionType) -> Color {
        switch type {
        case .work: return work
        case .shortBreak: return shortBreak
        case .longBreak: return longBreak
        }
    }

    static func == (lhs: VisualTheme, rhs: VisualTheme) -> Bool { lhs.id == rhs.id }
}

extension VisualTheme {
    /// Refined (default, Free) — flat, high-contrast, near-black in dark.
    static let refined = VisualTheme(
        id: "refined", name: "Refined", tier: .free,
        canvas: Color(hexLight: "F5F5F7", hexDark: "141417"),
        surface: Color(hexLight: "FFFFFF", hexDark: "1D1D22"),
        ink: .primary,
        accent: Color(hex: "FF9D3B"),
        work: Color(hexLight: "E88420", hexDark: "FF9D3B"),
        shortBreak: Color(hexLight: "34C08F", hexDark: "45D6A3"),
        longBreak: Color(hex: "3CBBD9"),
        supportsAccentChoice: true
    )

    /// Ambient (Pro) — meditative dusk mood, softer desaturated tints.
    static let ambient = VisualTheme(
        id: "ambient", name: "Ambient", tier: .pro,
        canvas: Color(hexLight: "ECE4DA", hexDark: "1A1522"),
        surface: Color(hexLight: "FAF6EF", hexDark: "241B2E"),
        ink: Color(hexLight: "2A2636", hexDark: "EDE7F0"),
        accent: Color(hexLight: "C98E46", hexDark: "E0A35C"),
        work: Color(hexLight: "C98E46", hexDark: "E0A35C"),
        shortBreak: Color(hexLight: "69A382", hexDark: "8FBFA6"),
        longBreak: Color(hexLight: "5B86AD", hexDark: "6F9FC0"),
        supportsAccentChoice: false
    )

    /// Matcha (Pro) — cozy matcha-latte, light-first, high-contrast ink numerals.
    static let matcha = VisualTheme(
        id: "matcha", name: "Matcha", tier: .pro,
        canvas: Color(hexLight: "F4EFE1", hexDark: "161C14"),
        surface: Color(hexLight: "FBF7EC", hexDark: "212A1E"),
        ink: Color(hexLight: "2A2A22", hexDark: "EDE7D6"),
        accent: Color(hexLight: "6E9A4E", hexDark: "9AC46E"),
        work: Color(hexLight: "6E9A4E", hexDark: "9AC46E"),
        shortBreak: Color(hexLight: "E3A15A", hexDark: "F0B570"),
        longBreak: Color(hexLight: "B4735A", hexDark: "CE8E72"),
        supportsAccentChoice: false
    )

    /// Terminal (Pro) — retro-CRT phosphor on near-black, monospace, dark-first.
    static let terminal = VisualTheme(
        id: "terminal", name: "Terminal", tier: .pro,
        canvas: Color(hexLight: "F3F0E7", hexDark: "07090C"),
        surface: Color(hexLight: "FBF8F0", hexDark: "0C1014"),
        ink: Color(hexLight: "1A1A17", hexDark: "E6EDE6"),
        accent: Color(hexLight: "1E7A44", hexDark: "3BE382"),
        work: Color(hexLight: "B36B00", hexDark: "FFB000"),
        shortBreak: Color(hexLight: "1E7A44", hexDark: "3BE382"),
        longBreak: Color(hexLight: "1D7FA6", hexDark: "35C8FF"),
        supportsAccentChoice: false
    )
}
