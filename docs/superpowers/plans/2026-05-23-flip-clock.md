# Flip Clock Screensaver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a third screensaver mode — a SwiftUI flip clock that ticks every second, with classic split-flap tile animation.

**Architecture:** Two new SwiftUI files. `FlipTile.swift` owns one digit's two-layer rendering + two-stage flip animation (0°→−90° easeIn → instant mirror → −90°→−180° easeOut, ~0.6 s total). `FlipClockView.swift` owns the 1 Hz `Timer`, locale detection, and the HStack of tiles + colon separators. Hooked into the existing `ScreensaverID` enum + `ContentView` switch.

**Tech Stack:** Swift 6, SwiftUI, macOS 14+. No Metal, no external dependencies.

**Testing approach:** Project has no test target (`project.yml` defines a single application target only). Per the spec, acceptance is visual. Each task's "verification" step is `xcodebuild` (must succeed) + a manual visual check described in the step. Do not add a test target — it's out of scope.

**Reference:** Spec at `docs/superpowers/specs/2026-05-23-flip-clock-design.md`. Animation reference: `KDTechniques/countdown-flipper-swiftui` — port the structure of `TopLayerView` / `BottomLayerView` / `CountdownFlipperViewModel.flipSectionToplayer`, drop the MVVM split (single SwiftUI view with `@State`), drop the `flipFromBottom` variant.

**Build invariant:** After every code change run:
```
cd /Users/artyom/Documents/work/wokyis-screensaver
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```
`xcodegen generate` re-emits the `.xcodeproj` from `project.yml`. New `.swift` files under `WokyisScreensaver/` are picked up automatically because `project.yml` lists `sources: - path: WokyisScreensaver`.

**Run command** (for visual verification):
```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```
The app launches in a window. Hover-move the mouse near the top to summon the picker, then click the screensaver name. `Esc` or `Cmd+Q` quits.

---

## Task 1: Add `flipClock` case to `ScreensaverID`, render a placeholder

Wire the new screensaver into the picker first, with a minimal placeholder view. This proves the integration before we build the actual clock — keeps the diff small if something is wrong.

**Files:**
- Modify: `WokyisScreensaver/Screensaver.swift`
- Modify: `WokyisScreensaver/ContentView.swift:72-80`
- Create: `WokyisScreensaver/FlipClockView.swift`

- [ ] **Step 1.1: Add `flipClock` to `ScreensaverID` enum**

Edit `WokyisScreensaver/Screensaver.swift` to:

```swift
import Foundation

enum ScreensaverID: String, CaseIterable, Identifiable {
    case noise = "noise"
    case gameOfLife = "game_of_life"
    case flipClock = "flip_clock"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .noise:      return "Topographic"
        case .gameOfLife: return "Game of Life"
        case .flipClock:  return "Flip Clock"
        }
    }
}
```

- [ ] **Step 1.2: Create placeholder `FlipClockView.swift`**

Create `WokyisScreensaver/FlipClockView.swift`:

```swift
import SwiftUI

struct FlipClockView: View {
    var body: some View {
        ZStack {
            Color.black
            Text("flip clock — placeholder")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
        }
    }
}

#Preview {
    FlipClockView()
        .frame(width: 800, height: 500)
}
```

- [ ] **Step 1.3: Add the new case to the view switch**

In `WokyisScreensaver/ContentView.swift`, replace the `screensaverView(for:)` function (currently lines 72–80) with:

```swift
@ViewBuilder
private func screensaverView(for id: ScreensaverID) -> some View {
    switch id {
    case .noise:
        MetalView(settings: noiseSettings)
    case .gameOfLife:
        GameOfLifeView(palette: palette.wrappedValue, reseedTick: golReseedTick)
    case .flipClock:
        FlipClockView()
    }
}
```

- [ ] **Step 1.4: Regenerate project and build**

```
cd /Users/artyom/Documents/work/wokyis-screensaver
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```

Expected: `** BUILD SUCCEEDED **`. If the build fails because of an unrelated `Info.plist` working-tree modification, leave it alone — that file is not part of this task.

- [ ] **Step 1.5: Visual check**

```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```

Move the mouse to summon the picker. Confirm:
1. A third pill labelled `Flip Clock` appears after `Game of Life`.
2. Clicking it switches to a black screen with the text `flip clock — placeholder`.
3. Clicking back to `Topographic` or `Game of Life` works.

Quit the app (`Cmd+Q`).

- [ ] **Step 1.6: Commit**

```
git add WokyisScreensaver/Screensaver.swift WokyisScreensaver/ContentView.swift WokyisScreensaver/FlipClockView.swift
git commit -m "add flip clock screensaver case with placeholder view"
```

---

## Task 2: Static `FlipTile` view (no animation yet)

Build a single, non-animating tile that shows one digit as two stacked half-cards. Compose six of them in a row inside `FlipClockView` to check sizing and layout before adding animation.

**Files:**
- Create: `WokyisScreensaver/FlipTile.swift`
- Modify: `WokyisScreensaver/FlipClockView.swift`

- [ ] **Step 2.1: Create `FlipTile.swift` (static version)**

Create `WokyisScreensaver/FlipTile.swift`:

```swift
import SwiftUI

/// A single-digit flip-clock tile. Two stacked rounded half-cards
/// (large outer corners, small inner corners) with a thin gap between
/// them — the gap is the "split line".
///
/// Static placeholder for now; flip animation is added in a later step.
struct FlipTile: View {
    let digit: Int
    let size: CGFloat   // controls font + frame; everything else scales off this

    private var width: CGFloat { size * 0.72 }
    private var height: CGFloat { size * 1.10 }
    private var gap: CGFloat { max(2, size * 0.012) }
    private var halfHeight: CGFloat { (height - gap) / 2 }
    private var radiusLarge: CGFloat { size * 0.08 }
    private var radiusSmall: CGFloat { size * 0.015 }

    private let tileColor = Color(white: 0.18)
    private let digitColor = Color(white: 0.92)

    var body: some View {
        VStack(spacing: gap) {
            halfCard(alignment: .top)
            halfCard(alignment: .bottom)
        }
        .frame(width: width, height: height)
    }

    private func halfCard(alignment: Alignment) -> some View {
        ZStack(alignment: alignment) {
            cardShape(alignment: alignment)
                .fill(tileColor)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .frame(height: halfHeight)

            Text("\(digit)")
                .font(.system(size: size, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(digitColor)
                .frame(width: width, height: height)
                .mask(alignment: alignment) {
                    Rectangle().frame(height: halfHeight)
                }
        }
        .frame(width: width, height: halfHeight, alignment: alignment)
    }

    private func cardShape(alignment: Alignment) -> UnevenRoundedRectangle {
        let isTop = alignment == .top
        return UnevenRoundedRectangle(
            topLeadingRadius:     isTop ? radiusLarge : radiusSmall,
            bottomLeadingRadius:  isTop ? radiusSmall : radiusLarge,
            bottomTrailingRadius: isTop ? radiusSmall : radiusLarge,
            topTrailingRadius:    isTop ? radiusLarge : radiusSmall
        )
    }
}

#Preview {
    HStack(spacing: 4) {
        FlipTile(digit: 1, size: 200)
        FlipTile(digit: 2, size: 200)
        FlipTile(digit: 3, size: 200)
    }
    .padding()
    .background(Color.black)
}
```

- [ ] **Step 2.2: Wire six tiles into `FlipClockView`**

Replace `WokyisScreensaver/FlipClockView.swift` with:

```swift
import SwiftUI

struct FlipClockView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = tileSize(for: proxy.size)
            ZStack {
                Color.black
                HStack(spacing: size * 0.08) {
                    pair(tens: 1, units: 2, size: size)
                    colonSeparator(size: size)
                    pair(tens: 3, units: 4, size: size)
                    colonSeparator(size: size)
                    pair(tens: 5, units: 6, size: size)
                }
            }
        }
        .ignoresSafeArea()
    }

    // Six tiles + two colon gaps must fit horizontally with margin.
    // Tile width ≈ size * 0.72, so total ≈ 6*0.72*size + 2*gap*size.
    // Pick size from the smaller of (width budget) and (height budget).
    private func tileSize(for container: CGSize) -> CGFloat {
        let widthBudget = container.width * 0.92
        let heightBudget = container.height * 0.65
        let widthDriven = widthBudget / (6 * 0.72 + 2 * 0.6)   // colons take ~0.6 * size
        let heightDriven = heightBudget / 1.10
        return min(widthDriven, heightDriven)
    }

    private func pair(tens: Int, units: Int, size: CGFloat) -> some View {
        HStack(spacing: size * 0.04) {
            FlipTile(digit: tens, size: size)
            FlipTile(digit: units, size: size)
        }
    }

    private func colonSeparator(size: CGFloat) -> some View {
        VStack(spacing: size * 0.30) {
            Circle().frame(width: size * 0.10, height: size * 0.10)
            Circle().frame(width: size * 0.10, height: size * 0.10)
        }
        .foregroundStyle(Color(white: 0.45))
        .frame(width: size * 0.6, height: size * 1.10)
    }
}

#Preview {
    FlipClockView()
        .frame(width: 1200, height: 600)
}
```

- [ ] **Step 2.3: Build**

```
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 2.4: Visual check**

```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```

Switch to `Flip Clock` from the picker. Confirm:
1. You see six dark rounded tiles arranged as `12 : 34 : 56`.
2. Each tile has a thin horizontal gap roughly through the middle.
3. The digit is visible across both halves with the gap cutting through it.
4. Resizing the window scales everything proportionally.
5. No layout breaks at very narrow / very wide aspect ratios.

Quit.

- [ ] **Step 2.5: Commit**

```
git add WokyisScreensaver/FlipTile.swift WokyisScreensaver/FlipClockView.swift
git commit -m "render static flip clock tiles"
```

---

## Task 3: Wire `FlipClockView` to the wall clock

Replace the hard-coded `12:34:56` with the real time. Tick every second. Still no flip animation — the digits change instantly. This isolates the time-source logic.

**Files:**
- Modify: `WokyisScreensaver/FlipClockView.swift`

- [ ] **Step 3.1: Replace `FlipClockView` with live-time version**

Overwrite `WokyisScreensaver/FlipClockView.swift` with:

```swift
import SwiftUI

struct FlipClockView: View {
    static let showSeconds: Bool = true   // flip to false once visuals are validated

    @State private var digits: TimeDigits = .zero
    @State private var timer: Timer?
    @State private var is24Hour: Bool = FlipClockView.locale24Hour()
    @State private var isPM: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let size = tileSize(for: proxy.size, showSeconds: Self.showSeconds)
            ZStack {
                Color.black
                HStack(spacing: size * 0.08) {
                    pair(tens: digits.h1, units: digits.h2, size: size)
                    colonSeparator(size: size)
                    pair(tens: digits.m1, units: digits.m2, size: size)
                    if Self.showSeconds {
                        colonSeparator(size: size)
                        pair(tens: digits.s1, units: digits.s2, size: size)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            digits = currentDigits()
            startTimer()
        }
        .onDisappear { stopTimer() }
    }

    // MARK: layout

    private func tileSize(for container: CGSize, showSeconds: Bool) -> CGFloat {
        let tileCount: CGFloat = showSeconds ? 6 : 4
        let colonCount: CGFloat = showSeconds ? 2 : 1
        let widthBudget = container.width * 0.92
        let heightBudget = container.height * 0.65
        let widthDriven = widthBudget / (tileCount * 0.72 + colonCount * 0.6)
        let heightDriven = heightBudget / 1.10
        return min(widthDriven, heightDriven)
    }

    private func pair(tens: Int, units: Int, size: CGFloat) -> some View {
        HStack(spacing: size * 0.04) {
            FlipTile(digit: tens, size: size)
            FlipTile(digit: units, size: size)
        }
    }

    private func colonSeparator(size: CGFloat) -> some View {
        VStack(spacing: size * 0.30) {
            Circle().frame(width: size * 0.10, height: size * 0.10)
            Circle().frame(width: size * 0.10, height: size * 0.10)
        }
        .foregroundStyle(Color(white: 0.45))
        .frame(width: size * 0.6, height: size * 1.10)
    }

    // MARK: time source

    /// Flip animation will take ~0.6 s; offset the displayed time so the flip
    /// is centred on the wall-clock second rather than lagging behind it.
    private static let flipDuration: TimeInterval = 0.6

    private func startTimer() {
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                digits = currentDigits()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func currentDigits() -> TimeDigits {
        let now = Date().addingTimeInterval(Self.flipDuration)
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: now)
        let hour24 = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let second = comps.second ?? 0

        let displayHour: Int
        if is24Hour {
            displayHour = hour24
        } else {
            let h = hour24 % 12
            displayHour = h == 0 ? 12 : h
        }
        isPM = hour24 >= 12

        return TimeDigits(
            h1: displayHour / 10,
            h2: displayHour % 10,
            m1: minute / 10,
            m2: minute % 10,
            s1: second / 10,
            s2: second % 10
        )
    }

    /// Probes the system locale for whether it uses 24-hour time.
    /// `dateFormat(fromTemplate: "j", ...)` returns "H" (24h) or "h" (12h).
    private static func locale24Hour() -> Bool {
        let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "H"
        return template.contains("H")
    }
}

struct TimeDigits: Equatable {
    var h1, h2, m1, m2, s1, s2: Int
    static let zero = TimeDigits(h1: 0, h2: 0, m1: 0, m2: 0, s1: 0, s2: 0)
}

#Preview {
    FlipClockView()
        .frame(width: 1200, height: 600)
}
```

- [ ] **Step 3.2: Build**

```
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3.3: Visual check**

```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```

Switch to `Flip Clock`. Confirm:
1. The displayed time matches your menu-bar clock (within ~1 second).
2. The seconds tile changes every second (instant change — no animation yet).
3. Minutes / hours roll over correctly.
4. Switching to another screensaver and back resumes ticking with current time.

Optional: switch macOS between a 12h and a 24h locale (System Settings → General → Language & Region → Time Format). The display should adjust on next launch.

Quit.

- [ ] **Step 3.4: Commit**

```
git add WokyisScreensaver/FlipClockView.swift
git commit -m "drive flip clock from wall time with locale-aware format"
```

---

## Task 4: Flip animation in `FlipTile`

Replace the static tile with the two-stage flip. Tile takes a `digit: Int` and animates whenever the value changes.

**Files:**
- Modify: `WokyisScreensaver/FlipTile.swift`

- [ ] **Step 4.1: Replace `FlipTile.swift` with animated version**

Overwrite `WokyisScreensaver/FlipTile.swift` with:

```swift
import SwiftUI

/// One digit. When `digit` changes, plays a two-stage X-axis flip
/// (0 → −90°, easeIn 0.3 s; mirror content; −90° → −180°, easeOut 0.3 s).
struct FlipTile: View {
    let digit: Int
    let size: CGFloat

    /// Visible digit on the static bottom layer.
    /// Updated to `digit` *before* the flip starts — the new digit's bottom
    /// half is what the flying top layer reveals as it rotates past −90°.
    @State private var bottomLayerDigit: Int

    /// Visible digit on the flying top layer.
    /// Holds the OLD digit during the first half of the flip (0 → −90°);
    /// swapped to the new digit at the midpoint when the layer is edge-on.
    @State private var topLayerDigit: Int

    @State private var angleX: CGFloat = 0
    @State private var angleY: CGFloat = 0
    @State private var angleZ: CGFloat = 0

    @State private var flipTask: Task<Void, Never>?

    init(digit: Int, size: CGFloat) {
        self.digit = digit
        self.size = size
        self._bottomLayerDigit = State(initialValue: digit)
        self._topLayerDigit = State(initialValue: digit)
    }

    // MARK: layout constants
    private var width: CGFloat { size * 0.72 }
    private var height: CGFloat { size * 1.10 }
    private var gap: CGFloat { max(2, size * 0.012) }
    private var halfHeight: CGFloat { (height - gap) / 2 }
    private var radiusLarge: CGFloat { size * 0.08 }
    private var radiusSmall: CGFloat { size * 0.015 }

    private let tileColor = Color(white: 0.18)
    private let digitColor = Color(white: 0.92)
    /// One half of the full flip (0 → −90° or −90° → −180°). Full flip = 2 × this.
    private let stageDuration: TimeInterval = 0.3

    var body: some View {
        ZStack {
            // Static bottom layer: shows `bottomLayerDigit`.
            // While idle, its top half is hidden behind the un-rotated top layer.
            staticTile(showing: bottomLayerDigit)

            // Flying top layer. Holds `topLayerDigit`, rotates around its
            // bottom edge (top half flips down).
            flyingTopLayer(showing: topLayerDigit)
        }
        .frame(width: width, height: height)
        .onChange(of: digit) { _, newValue in
            startFlip(to: newValue)
        }
        .onDisappear { flipTask?.cancel() }
    }

    // MARK: subviews

    private func staticTile(showing value: Int) -> some View {
        VStack(spacing: gap) {
            halfCard(alignment: .top, value: value)
            halfCard(alignment: .bottom, value: value)
        }
    }

    /// The flying top layer renders BOTH halves of a tile but they appear
    /// during different stages of the flip: the upper half (which is the
    /// part anchored at `.top`) is what the user sees during the first half
    /// of the rotation. After the mid-flip Y/Z mirror, the lower half becomes
    /// what the user sees as the rotation completes.
    private func flyingTopLayer(showing value: Int) -> some View {
        VStack(spacing: gap) {
            halfCard(alignment: .top, value: value)
            halfCard(alignment: .bottom, value: value)
        }
        // Mid-flip mirror — applied to the *content* of the rotating layer,
        // not the X rotation itself.
        .rotation3DEffect(.degrees(angleY), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(angleZ), axis: (x: 0, y: 0, z: 1))
        // Main flip rotation, around the centre line of the tile.
        .rotation3DEffect(
            .degrees(angleX),
            axis: (x: 1, y: 0, z: 0),
            anchor: .center,
            anchorZ: 0,
            perspective: 0.5
        )
    }

    private func halfCard(alignment: Alignment, value: Int) -> some View {
        ZStack(alignment: alignment) {
            cardShape(alignment: alignment)
                .fill(tileColor)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .frame(height: halfHeight)

            Text("\(value)")
                .font(.system(size: size, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(digitColor)
                .frame(width: width, height: height)
                .mask(alignment: alignment) {
                    Rectangle().frame(height: halfHeight)
                }
        }
        .frame(width: width, height: halfHeight, alignment: alignment)
    }

    private func cardShape(alignment: Alignment) -> UnevenRoundedRectangle {
        let isTop = alignment == .top
        return UnevenRoundedRectangle(
            topLeadingRadius:     isTop ? radiusLarge : radiusSmall,
            bottomLeadingRadius:  isTop ? radiusSmall : radiusLarge,
            bottomTrailingRadius: isTop ? radiusSmall : radiusLarge,
            topTrailingRadius:    isTop ? radiusLarge : radiusSmall
        )
    }

    // MARK: animation

    private func startFlip(to newDigit: Int) {
        flipTask?.cancel()
        flipTask = Task { @MainActor in
            // Stage 0: the next digit is already what the bottom-layer
            // bottom-half should show when the top layer flips past −90°.
            bottomLayerDigit = newDigit

            // Stage 1: rotate top layer 0 → −90°, easeIn.
            withAnimation(.easeIn(duration: stageDuration)) {
                angleX = -90
            }
            try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
            if Task.isCancelled { return }

            // Stage 2 (instant, at angleX = −90°, tile is edge-on so invisible):
            //  - mirror the layer's content via Y+Z 180° so the back side reads correctly,
            //  - swap top-layer digit to the new value.
            angleY = 180
            angleZ = 180
            topLayerDigit = newDigit

            // Stage 3: rotate −90° → −180°, easeOut. Bottom half of new digit
            // settles into place on top of the static bottom layer.
            withAnimation(.easeOut(duration: stageDuration)) {
                angleX = -180
            }
            try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
            if Task.isCancelled { return }

            // Reset: hide the flying layer's mirror, snap rotation back to 0.
            // No animation — the visual is identical (the static layer now
            // shows the new digit on both halves).
            angleX = 0
            angleY = 0
            angleZ = 0
        }
    }
}

#Preview {
    @Previewable @State var d: Int = 0
    VStack(spacing: 20) {
        FlipTile(digit: d, size: 200)
        Button("flip → \((d + 1) % 10)") { d = (d + 1) % 10 }
    }
    .padding()
    .background(Color.black)
}
```

- [ ] **Step 4.2: Build**

```
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4.3: Visual check — the critical one**

```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```

Switch to `Flip Clock`. Watch the seconds-units tile. Confirm:
1. Every second, the tile flips: top half rotates down, edge-on at the middle, then settles as the bottom half of the new digit.
2. No visible "garbled" content at the midpoint (the Y+Z mirror is doing its job).
3. Other tiles only flip when they need to (s1 every 10 s; m2 every 60 s; etc.).
4. The animation feels smooth, ~0.6 s per flip — not jittery.
5. If you switch screensavers mid-flip and come back, no stuck tiles.

If any of those fail, the most likely culprits are:
- Garbled midpoint → check that `angleY` and `angleZ` are both set to 180 at stage 2 (one without the other reads as a mirror without the matching second flip).
- Tile flipping but background shows through during rotation → expected (perspective is set to 0.5); if it's distracting, reduce to 0.3.
- Flip plays on every appearance, including first → the `init` should have set both `_topLayerDigit` and `_bottomLayerDigit` to `digit`, so `.onChange` only fires on real changes.

Quit.

- [ ] **Step 4.4: Commit**

```
git add WokyisScreensaver/FlipTile.swift
git commit -m "animate flip clock tiles with two-stage X-axis rotation"
```

---

## Task 5: Shadow gradient during flip

Without shading, the rotating tile looks like a 2D billboard rather than a solid card. Add a `LinearGradient` overlay that strengthens during stage 1 and fades during stage 3, matching the reference library's `changeColorOnCounterIncrement` / `clearColorOnFirstHalfRotation` pattern.

**Files:**
- Modify: `WokyisScreensaver/FlipTile.swift`

- [ ] **Step 5.1: Add gradient overlay + animate its opacity in lockstep with the rotation**

In `WokyisScreensaver/FlipTile.swift`:

a) Add a new `@State` after the angle states:

```swift
@State private var shadeOpacity: CGFloat = 0
```

b) Add the gradient as an overlay inside `halfCard`. Replace the existing `halfCard(alignment:value:)` with:

```swift
private func halfCard(alignment: Alignment, value: Int) -> some View {
    ZStack(alignment: alignment) {
        cardShape(alignment: alignment)
            .fill(tileColor)
            .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
            .frame(height: halfHeight)

        Text("\(value)")
            .font(.system(size: size, weight: .semibold))
            .fontDesign(.rounded)
            .foregroundStyle(digitColor)
            .frame(width: width, height: height)
            .mask(alignment: alignment) {
                Rectangle().frame(height: halfHeight)
            }
    }
    .frame(width: width, height: halfHeight, alignment: alignment)
}
```

(Unchanged. The overlay is applied to the *flying layer*, not the static one — see the next change.)

c) Replace `flyingTopLayer(showing:)` with a version that overlays the shading gradient on the upper half of the rotating content:

```swift
private func flyingTopLayer(showing value: Int) -> some View {
    VStack(spacing: gap) {
        halfCard(alignment: .top, value: value)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(shadeOpacity), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: halfHeight)
                .allowsHitTesting(false)
            }
        halfCard(alignment: .bottom, value: value)
    }
    .rotation3DEffect(.degrees(angleY), axis: (x: 0, y: 1, z: 0))
    .rotation3DEffect(.degrees(angleZ), axis: (x: 0, y: 0, z: 1))
    .rotation3DEffect(
        .degrees(angleX),
        axis: (x: 1, y: 0, z: 0),
        anchor: .center,
        anchorZ: 0,
        perspective: 0.5
    )
}
```

d) Animate `shadeOpacity` inside `startFlip(to:)`. Replace the body of `startFlip` with:

```swift
private func startFlip(to newDigit: Int) {
    flipTask?.cancel()
    flipTask = Task { @MainActor in
        bottomLayerDigit = newDigit

        withAnimation(.easeIn(duration: stageDuration)) {
            angleX = -90
            shadeOpacity = 0.6
        }
        try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
        if Task.isCancelled { return }

        // At edge-on: clear the shade so the back side starts bright,
        // mirror the content, swap to the new digit.
        shadeOpacity = 0
        angleY = 180
        angleZ = 180
        topLayerDigit = newDigit

        withAnimation(.easeOut(duration: stageDuration)) {
            angleX = -180
        }
        try? await Task.sleep(nanoseconds: UInt64(stageDuration * 1_000_000_000))
        if Task.isCancelled { return }

        angleX = 0
        angleY = 0
        angleZ = 0
    }
}
```

- [ ] **Step 5.2: Build**

```
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5.3: Visual check**

```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```

Confirm the flipping tile now has visible depth — the upper half darkens as it rotates away, then the new bottom half settles cleanly without lingering shadow. The flip should feel like a falling card, not a 2D billboard. If the shadow looks too heavy, reduce `0.6` to `0.4`; too light, raise to `0.8`.

Quit.

- [ ] **Step 5.4: Commit**

```
git add WokyisScreensaver/FlipTile.swift
git commit -m "shade flipping tile during rotation for depth"
```

---

## Task 6: AM/PM indicator on 12-hour locales

In a 24-hour locale this task is a no-op visually. In a 12-hour locale, a small `AM` / `PM` label appears to the right of the clock and updates at noon / midnight. No flip — static label.

**Files:**
- Modify: `WokyisScreensaver/FlipClockView.swift`

- [ ] **Step 6.1: Add the AM/PM label to the HStack**

In `WokyisScreensaver/FlipClockView.swift`, replace the inner `HStack` inside `body` with:

```swift
HStack(spacing: size * 0.08) {
    pair(tens: digits.h1, units: digits.h2, size: size)
    colonSeparator(size: size)
    pair(tens: digits.m1, units: digits.m2, size: size)
    if Self.showSeconds {
        colonSeparator(size: size)
        pair(tens: digits.s1, units: digits.s2, size: size)
    }
    if !is24Hour {
        Text(isPM ? "PM" : "AM")
            .font(.system(size: size * 0.18, weight: .semibold))
            .fontDesign(.rounded)
            .foregroundStyle(Color(white: 0.55))
            .padding(.leading, size * 0.10)
    }
}
```

Also adjust `tileSize(for:showSeconds:)` so the AM/PM label has room. Replace it with:

```swift
private func tileSize(for container: CGSize, showSeconds: Bool) -> CGFloat {
    let tileCount: CGFloat = showSeconds ? 6 : 4
    let colonCount: CGFloat = showSeconds ? 2 : 1
    let ampmAllowance: CGFloat = is24Hour ? 0 : 0.6
    let widthBudget = container.width * 0.92
    let heightBudget = container.height * 0.65
    let widthDriven = widthBudget / (tileCount * 0.72 + colonCount * 0.6 + ampmAllowance)
    let heightDriven = heightBudget / 1.10
    return min(widthDriven, heightDriven)
}
```

- [ ] **Step 6.2: Build**

```
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6.3: Visual check (24h locale)**

If your macOS is in a 24h locale (e.g. `ru_RU`):

```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```

Confirm: no AM/PM label appears, layout is unchanged from Task 5.

Optionally, temporarily flip your locale to a 12h one in System Settings → General → Language & Region → Time Format, relaunch, and confirm the `AM` / `PM` label appears next to the clock and reads correctly. Restore your preferred locale afterwards.

Quit.

- [ ] **Step 6.4: Commit**

```
git add WokyisScreensaver/FlipClockView.swift
git commit -m "show AM/PM label on 12-hour locales"
```

---

## Task 7: Drop seconds (final visual)

Once you've confirmed the flipping looks correct *with* seconds (which gives you a flip every second to inspect), switch to the production layout: `HH:MM` only. The plumbing already supports it — flip `showSeconds` to `false`.

**Files:**
- Modify: `WokyisScreensaver/FlipClockView.swift`

- [ ] **Step 7.1: Confirm with the user before flipping the toggle**

Before doing this task, message the user: "Seconds layout looks good. Switching to HH:MM (`showSeconds = false`) — confirm?" Wait for confirmation.

This is the only deliberately gated step. The user reserved the right to keep seconds-on if they prefer the look.

- [ ] **Step 7.2: Flip the toggle**

In `WokyisScreensaver/FlipClockView.swift`, change:

```swift
static let showSeconds: Bool = true   // flip to false once visuals are validated
```

to:

```swift
static let showSeconds: Bool = false
```

- [ ] **Step 7.3: Build**

```
xcodegen generate
xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7.4: Visual check**

```
open dist/build/Build/Products/Debug/WokyisScreensaver.app
```

Confirm:
1. Only `HH:MM` is displayed — four tiles + one colon.
2. Tiles are larger (more screen real estate to share between fewer tiles).
3. Minute-units flips every minute. No flip activity for ~60 s at a time on the other tiles, then they cascade as needed.
4. Layout still works on resize / different aspect ratios.

Quit.

- [ ] **Step 7.5: Commit**

```
git add WokyisScreensaver/FlipClockView.swift
git commit -m "drop seconds — flip clock displays HH:MM"
```

---

## Done

The flip clock screensaver is feature-complete per the spec. The `showSeconds` flag remains in source as a code-level knob; future changes to it are one-line.
