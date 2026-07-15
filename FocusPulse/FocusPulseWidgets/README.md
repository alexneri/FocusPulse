# FocusPulse Widgets

Source for the FocusPulse **widget extension** — Home Screen + Lock Screen widgets, Live Activity,
and Dynamic Island (Epic 5, Stories 5.2–5.5). These files are intentionally **not** part of the app
target's synchronized group, so they never compile into the app.

The app side is already done: `TimerEngine` writes `SharedTimerState` to the App Group and calls
`WidgetCenter.reloadAllTimelines()` on every transition, so the widgets light up as soon as the
target exists.

## Add the extension target (one-time, in Xcode)

1. **File → New → Target… → Widget Extension.** Name it `FocusPulseWidgets`; keep "Include Live
   Activity" checked. Bundle id `net.sg-r.FocusPulse.FocusPulseWidgets`.
2. Replace the generated files with the ones in this folder (or point the new target's group here),
   and use this `Info.plist`. The bundle uses `StaticConfiguration` (no configuration intent).
3. **Shared type:** add the app's `FocusPulse/Shared/SharedTimerState.swift` to the widget target's
   **Target Membership** so both targets share `SharedTimerState` + `AppGroup`.
4. **App Group:** in *Signing & Capabilities*, add **App Groups → `group.net.sg-r.FocusPulse`** to
   **both** the app and widget targets (register it on the Apple Developer account for device builds).
5. **Live Activities:** add `NSSupportsLiveActivities = YES` to the **app**'s Info.plist.
6. **Deep links:** register the `focuspulse` URL scheme on the app; handle `focuspulse://pause` and
   `://skip` in `onOpenURL` (drives `TimerEngine.pause()/skip()` from the Dynamic Island buttons).

## Remaining app-side wiring (Story 5.4)

A small `LiveActivityController` that starts `Activity<FocusTimerAttributes>` when a Work session
begins, pushes an `ActivityContent` update each tick, and ends it on stop/complete — add it to the
app once the shared `FocusTimerAttributes` type is visible to both targets. Graceful fallback: if
`ActivityAuthorizationInfo().areActivitiesEnabled` is false, skip silently (the timer is unaffected).
