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
    @StateObject private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeStore)
                .environmentObject(store)
                .tint(themeStore.activeAccent)
                .preferredColorScheme(themeStore.appearance.colorScheme)
        }
    }
}
