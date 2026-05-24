# Flip Clock Screensaver — Design

## Summary

A third screensaver mode alongside Topographic and Game of Life: a classic split-flap "flip clock" rendering the current time in HH:MM (with optional HH:MM:SS during development) as a row of dark rounded tiles that physically flip each time a digit changes.

## Goals

- Visually credible flip clock: each digit lives on its own card with a horizontal split line; only the changing digits animate.
- Animation style ported from `KDTechniques/countdown-flipper-swiftui` (two-stage `easeIn`/`easeOut` X-axis rotation through 180° with a mid-rotation content mirror; ~0.6 s per flip).
- Pure SwiftUI — no new Metal pipeline, no external dependencies.
- Locale-aware: 12h vs 24h follows macOS system settings (`Locale.current`).
- Slots cleanly into the existing `ScreensaverID` picker: select via the hover picker like Topographic / Game of Life.

## Non-Goals

- No settings UI for the clock (no font picker, color picker, layout toggle). Matches Topographic.
- No date row, no day-of-week, no timezone label. Just digits + colon separators (+ AM/PM indicator on 12h locales).
- No flip animation for the AM/PM indicator — static label.
- No customisable color theme; one tile style only.
- No sound, no tick effects.
- No countdown / timer / stopwatch mode. Wall clock only.

## Visual design

```
   ┌──┐┌──┐    ┌──┐┌──┐    ┌──┐┌──┐
   │ 2││3 │ :  │ 4││5 │ :  │ 0││9 │
   │──││──│    │──││──│    │──││──│   ← split line, full-tile width
   │ 2││3 │    │ 4││5 │    │ 0││9 │
   └──┘└──┘    └──┘└──┘    └──┘└──┘
   HOURS       MINUTES     SECONDS
```

- Background: solid black (matches the rest of the app).
- Tile: dark gray (`Color(white: 0.18)` ballpark), large outer corners + small inner corners via `UnevenRoundedRectangle`, ~2 pt drop shadow.
- Digit color: near-white (`Color(white: 0.92)`).
- Split line: ~2 pt gap between top and bottom halves; the background bleeds through. No explicit drawn line — the gap is the line.
- Colon separator: two stacked dots, secondary-color, static (no blink).
- AM/PM (only when 12h locale): small uppercase label next to the seconds (or minutes if seconds hidden), static, no animation.
- Sizing: tiles scale to fit the window. Use `ViewThatFits` with two breakpoints (large / compact) like the reference repo, or compute font size from `GeometryReader` width. Pick the simpler one (`ViewThatFits`) in the plan.

## Animation

Per-digit flip, fired only when that digit's value changes.

State per `FlipTile`:

- `topLayerDigit: Int` — the digit shown on the rotating top layer.
- `bottomLayerDigit: Int` — the digit shown on the static bottom layer behind the top layer.
- `angleX, angleY, angleZ: CGFloat` — rotation angles for the top layer.
- `topShadow, bottomShadow: LinearGradient` — overlay gradients that strengthen during rotation to fake depth.

Flip sequence (current digit `old` → new digit `new`):

1. **Pre-flip:** set `bottomLayerDigit = new` (the bottom card "underneath" is already the new digit; we just can't see its top half yet because the top layer covers it).
2. **First half (0.3 s, easeIn):** `withAnimation` → `angleX = -90`. Simultaneously fade in `topShadow` to darken the top half as it approaches edge-on.
3. **Mid-flip mirror (instant, at angleX == -90°):** clear shadow; set `angleY = 180` and `angleZ = 180` (mirror the content backside); set `topLayerDigit = new`. Visually the tile is edge-on so the mirror is invisible.
4. **Second half (0.3 s, easeOut):** `withAnimation` → `angleX = -180`. The top layer now lands as the bottom half of the new digit, sitting on top of the static bottom layer.
5. **Reset:** at the end, set `topLayerDigit = new`, `bottomLayerDigit = new`, `angleX = angleY = angleZ = 0`, clear gradients. The tile is again statically displaying `new`.

Only `flipFromTop` direction (top half falls down). Clock only increments; 9→0 still looks correct flipping down.

Two-stage animation is sequenced with `Task.sleep` between `withAnimation` blocks, matching the library's `flipSectionToplayer()` function.

## Time source

- A single `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)` in `FlipClockView`.
- On each tick, read `Date().addingTimeInterval(flipDuration)` where `flipDuration ≈ 0.6 s` (matches the library). With this offset, when the timer fires at wall-clock second `T`, the flip animates the displayed value from `T - 0.4` to `T + 0.6`, crossing the midpoint exactly when wall time reaches `T + 0.6` — i.e. the display is centred on the wall clock rather than lagging the full flip duration behind it.
- Decompose into `(h1, h2, m1, m2, s1, s2)` via `Calendar.current`. Push each value down to its `FlipTile`. SwiftUI's `.onChange(of: digit)` inside the tile fires the flip when (and only when) that specific digit changes.
- 12h vs 24h detection: probe `DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)` — contains `"h"` for 12h, `"H"` for 24h. Cache the result; locale doesn't change at runtime.
- Hours rendered with leading zero in both modes (e.g., `01:23` rather than `1:23`) for visual consistency — both tile positions are always filled.

## Architecture

New files (all under `WokyisScreensaver/`):

- `FlipClockView.swift` — top-level `View`. Owns the timer, computes `(h1, h2, m1, m2, s1, s2)`, decides 12h/24h + AM/PM, composes the row of tiles + separators. Public knob: `showSeconds: Bool` (default `true` during development, will be set to `false` once visuals are validated).
- `FlipTile.swift` — single-digit tile. Input: `digit: Int`. Encapsulates the two-layer view + the flip animation state machine. About 100–150 lines.

Changes to existing files:

- `Screensaver.swift` — add `case flipClock = "flip_clock"` with `displayName = "Flip Clock"`. Order in `allCases` decides position in the picker; new case goes last.
- `ContentView.swift` — extend `screensaverView(for:)` with the new case → `FlipClockView()`. No other plumbing required (the picker already iterates `ScreensaverID.allCases`; the hover-driven palette picker stays hidden because it's gated on `selection == .gameOfLife`).

No new assets, no new Metal shaders, no new project.yml entries (`sources: path: WokyisScreensaver` picks up new `.swift` files automatically).

## Edge cases / details

- **Timer drift:** `Timer.scheduledTimer` is not perfectly aligned to the wall clock second. Acceptable here — the visual is one-second-resolution and the eye won't catch sub-100ms drift. No `RunLoop.common` tweak needed unless we observe stalls.
- **Window resize:** `ViewThatFits` reflows automatically. Per-tile state survives because the tile identity (position in `HStack`) is stable.
- **First appearance:** initialise `topLayerDigit = bottomLayerDigit = currentDigit` so no flip animation fires on mount; tiles materialise already showing the correct time.
- **Background→foreground:** Timer continues firing while window is hidden (`Timer.scheduledTimer` runs on the main `RunLoop`). When the view re-appears, `.onChange(of: digit)` would fire for any digits that changed during hiding. To avoid a flurry of flips on return, debounce: if more than one digit changed in a single tick (which is the normal case), each tile still animates independently, but the visual is fine because they all start within ~50 ms of each other. No special handling needed unless QA finds it ugly.
- **Reduced motion:** out of scope for MVP. Could later honour `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`.

## Testing

- No unit tests. Acceptance is visual:
  1. App launches → flip clock selectable in picker.
  2. With seconds: every second the seconds-units tile flips; every 10 s the seconds-tens flips; every minute, minute-units flips, etc.
  3. Locale check: switch macOS to a 12h locale (e.g., `en_US`) — clock displays in 12h with AM/PM. Switch to a 24h locale (e.g., `ru_RU`) — clock displays in 24h, no AM/PM.
  4. Flip animation smooth, no flicker, no visible mirror artifact at the midpoint.
  5. Resize the window → tiles reflow / rescale.
  6. Switch to Topographic or Game of Life and back → flip clock resumes ticking with current time, no stuck tiles.

## Open questions / deferred

- Whether to drop seconds: deferred until visual validation is done. Spec keeps `showSeconds` as a code-level knob.
- AM/PM tile flip animation: not in MVP; static label is fine.
- A "wokyis" branded font / proportional font tuning: not in MVP. Use `.system(size:, weight: .bold)` with `.fontDesign(.rounded)` from the reference repo.
