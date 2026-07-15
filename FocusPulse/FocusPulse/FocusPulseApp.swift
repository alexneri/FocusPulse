//
//  FocusPulseApp.swift
//  FocusPulse
//
//  Created by Alexander N. V. Neri on 22/06/2025.
//

import SwiftUI

@main
struct FocusPulseApp: App {
    @StateObject private var themeStore = ThemeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeStore)
                .tint(themeStore.activeAccent)
                .preferredColorScheme(themeStore.appearance.colorScheme)
        }
    }
}
