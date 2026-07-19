import SwiftUI

// NOTE: Source for the FocusPulse Apple Watch app. NOT part of the iOS app target's synchronized
// group, so it never compiles into the phone app. In Xcode: add a watchOS App target
// "FocusPulseWatch" (bundle moe.sei.FocusPulse.watchkitapp, watchOS 11), give it these files plus
// the shared sources + the FocusPulseCore package, and enable App Group group.moe.sei.FocusPulse.
// Full checklist in README.md.

@main
struct FocusPulseWatchApp: App {
    // Theme + appearance are cached in the App Group and delivered from the phone over connectivity
    // (architecture §8.2), so the wrist matches the phone.
    @StateObject private var theme = ThemeStore(defaults: AppGroup.defaults ?? .standard)
    @StateObject private var model = WatchTimerViewModel()

    var body: some Scene {
        WindowGroup {
            WatchTimerView()
                .environmentObject(theme)
                .environmentObject(model)
                .tint(theme.activeAccent)
                .preferredColorScheme(theme.appearance.colorScheme)
        }
    }
}
