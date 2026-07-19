# FocusPulseWatch — Apple Watch companion (Epic 7)

Source for the FocusPulse Apple Watch app. Like `FocusPulseWidgets/`, this folder is **not** part
of the iOS app target's synchronized group, so nothing here compiles into the phone app until you
create the watch targets in Xcode and give them these files. Everything is written against the
verified `FocusPulseCore` domain and the shared theme/app-group types the phone app already uses.

## What's here

| File | Story | Role |
|------|-------|------|
| `FocusPulseWatchApp.swift` | 7.1 | `@main` watchOS App; injects `ThemeStore` + `WatchTimerViewModel`. |
| `WatchTimerView.swift` | 7.2 | The timer face: ring + tabular countdown, Play/Pause + Skip, cycle dots, idle Start, **Double Tap**, **Crown peek**, **Always-On collapse**. |
| `WatchTimerViewModel.swift` | 7.2–7.6 | Adapter over `FocusPulseCore.TimerEngine`; renders from one `TimerSnapshot`; local-drive vs mirror; routes taps via `TimerAuthority`. |
| `WatchConnectivityManager.swift` | 7.4 | `WCSession` transport (watch side); defers all decisions to `FocusPulseCore`. |
| `WatchRuntime.swift` | 7.3 | Date-based end-of-session notification (authoritative) + optional `WKExtendedRuntimeSession`. |
| `WatchComplications.swift` | 7.5 | Widget Extension: `.accessoryCircular/Corner/Rectangular/Inline`, full-color + tinted. |

The cross-device **policy** these files depend on — reconciliation, command routing, session
dedupe — lives in `FocusPulseCore` (`Services/WatchSync.swift`) and is unit-tested
(`WatchSyncTests`, `swift test`). The iPhone half is `FocusPulse/Connectivity/PhoneConnectivityManager.swift`
(already compiled into the app).

## Xcode setup (needs your Apple account for signing + App Group)

1. **Add a watchOS App target** `FocusPulseWatch` — File ▸ New ▸ Target ▸ watchOS ▸ App.
   - Bundle id `moe.sei.FocusPulse.watchkitapp`, watchOS **11.0** min, SwiftUI lifecycle.
   - Delete the stub `ContentView`/`App` Xcode generates; add the files in this folder instead.
2. **Add the FocusPulseCore package** to the watch target: target ▸ General ▸ Frameworks ▸ `+` ▸
   `FocusPulseCore`.
3. **Share source via Target Membership** — select each of these (already in the app) and tick the
   watch target in the File Inspector, so the wrist uses the same types, no duplication:
   - `FocusPulse/Theme/VisualTheme.swift`, `Theme/ThemeStore.swift`, `Theme/Color+Hex.swift`
   - `FocusPulse/Shared/SharedTimerState.swift`
4. **App Group** — add `group.moe.sei.FocusPulse` to the watch target's Signing & Capabilities
   (same id as the phone; it's a separate per-device container — App Groups do **not** bridge
   iPhone ↔ Watch, `WatchConnectivity` does).
5. **Notifications** — the watch target uses `UNUserNotificationCenter`; no extra capability, but
   call `WatchRuntime.shared.requestNotificationAuthorization()` once.
6. **Complications** — add a **Widget Extension** target embedded in the watch app
   (`moe.sei.FocusPulse.watchkitapp.complications`), add `WatchComplications.swift` to it, and give
   it membership of `Shared/SharedTimerState.swift` + the App Group.

## Wiring the two sides (Story 7.4 — do this with a paired device/simulator)

The phone half is inert until you connect it. In the app's `ViewModels/TimerEngine`
(`publishSharedState()`), also push to the watch and accept its updates:

```swift
private let watch = PhoneConnectivityManager.shared   // call watch.activate() in init

// inside publishSharedState():
watch.publish(state: core.state, sessionType: core.sessionType,
              remainingSeconds: core.remainingSeconds,
              totalSeconds: Int(core.configuration.duration(for: core.sessionType)),
              expectedEndDate: core.expectedEndDate,
              completedWorkSessions: core.completedWorkSessions,
              owner: core.state == .idle ? nil : .phone)

// in init, receive the watch's forwarded commands + winning snapshots:
watch.onCommandFromWatch = { [weak self] cmd in /* apply cmd to self.core */ }
watch.onRemoteSnapshot   = { [weak self] snap in /* adopt when the watch owns the session */ }
```

The watch side self-wires (`WatchTimerViewModel` activates connectivity in `init`).

## What still needs a real device (can't be verified headless)

- End-to-end `WCSession` handshake, reachability transitions, and the mirror↔local ownership swap.
- Always-On rendering + battery, Double Tap, and complication refresh cadence on hardware.
- `WKExtendedRuntimeSession` behavior under App Review (Story 7.3 flag).

The **policy** underneath all of the above is already proven by `WatchSyncTests`.
