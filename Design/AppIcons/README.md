# App Icons

Source: Claude Design (Fable). Concept = the FocusPulse progress ring ("the pulse").
Canvas `#141417`, Focus Orange `#FF9D3B` — matches the Refined theme tokens.
All exports are 1024×1024, RGB, **no alpha** (App Store safe).

| File | Concept | Role |
|------|---------|------|
| `pulse-primary-1024.png` | **1a Pulse** — 80% arc, glowing tip, empty center | **Default app icon** (wired into `AppIcon.appiconset`) |
| `comet-1024.png` | **1d Comet** — time as a burning tail | Alternate (Pro, Story 4.3) |
| `heartbeat-1024.png` | **1b Heartbeat** — still dot at center | Alternate (Pro, Story 4.3) |
| `glass-1024.png` | **1c Glass** — liquid-glass ring on track | Alternate (Pro, Story 4.3) |

## Wiring alternates (Story 4.3, not yet built)

Alternate app icons require loose PNG files in the bundle (not the asset catalog) plus
`CFBundleIcons` → `CFBundleAlternateIcons` in Info.plist, switched at runtime via
`UIApplication.shared.setAlternateIconName(_:)`. Gate the switcher behind Pro in the
Settings → Appearance section, alongside the theme picker.

Ideally the alternates get reskinned per theme palette (orange / dusk-indigo /
matcha-green / phosphor-green) so icon choice pairs with the active Visual Theme.
