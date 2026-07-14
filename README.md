# FocusPulse

A native iOS Pomodoro focus timer built for deep work — minimal surface area,
"set it and forget it" auto-cycling, deep Apple-ecosystem integration.

This repo is the **app implementation**. The full product + engineering spec lives in the
`ideahub` monorepo under `FocusPulse/docs/` (6 epics, 25 stories).

## Status

Early implementation. The platform-agnostic **Domain core is complete and logic-verified**:
the timer state machine, session cycler, configuration, session model, and statistics engine.

## Layout

- `Core/` — the `FocusPulseCore` SwiftPM package (pure Swift Domain layer; **no UIKit/SwiftUI**,
  so it compiles and is testable on any machine with the Swift toolchain).
  - `Sources/FocusPulseCore/Entities/` — `SessionType`, `TimerState`, `TimerConfiguration`,
    `FocusSession` (aggregate, invariant-checked), `DailyStat`.
  - `Sources/FocusPulseCore/Services/` — `TimerEngine` (the heart — a `@MainActor` state
    machine that derives remaining time from a clock diff, never `seconds -= 1`),
    `SessionCycler`, `StatisticsEngine`.
  - `Sources/FocusPulseCore/Interfaces/` — `SessionRepository`, `SettingsStore` (Domain ports).
  - `Sources/CoreCheck/` — a dependency-free assertion runner so the logic can be verified
    **without Xcode** (Command Line Tools only).
  - `Tests/FocusPulseCoreTests/` — the XCTest suite (runs under `swift test` in Xcode / CI).
- _(next)_ `App/`, `Presentation/`, `Data/`, `Widgets/` — the SwiftUI iOS app, built via Xcode.

## Verify the domain core (no Xcode needed)

```sh
cd Core && swift run CoreCheck      # runs the logic checks; exits non-zero on any failure
```

With full Xcode installed, run the real test suite:

```sh
cd Core && swift test
```

## Building the app

The iOS app target requires **full Xcode** with the iOS SDK and a Simulator. The machine this
was scaffolded on had only Command Line Tools, so the SwiftUI/CoreData/WidgetKit/StoreKit layers
are written to spec but not yet compiled here.

- Bundle ID `com.sgrsh.focuspulse` · iOS 17.0+ · Swift 6.2 (default main-actor isolation)
- Clean Architecture + MVVM+C · CoreData (CloudKit-ready) · StoreKit 2 · WidgetKit / ActivityKit
- Progressive enhancement: Liquid Glass (iOS 26), AlarmKit (iOS 18, v1.1)
