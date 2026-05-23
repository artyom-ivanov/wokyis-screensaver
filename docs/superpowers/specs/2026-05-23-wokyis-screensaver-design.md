# Wokyis Screensaver — Design

## Summary

A minimal fullscreen macOS app that renders smoothly animated topographic-style contour lines — white isolines on a black background, evolving continuously over a 3D simplex-noise field. No UI, no settings; `Esc` or `Cmd+Q` exits.

## Goals

- Resembles the reference: white isolines on solid black, smooth flowing curves with subtle gray edge.
- Opens fullscreen on launch (one display, main display).
- Animation is continuous, never repeats, evolves slowly.
- 60+ fps on a Retina/5K display, GPU-driven.
- Single source tree, buildable via Xcode (Cmd+R) — no external dependencies.

## Non-Goals (explicit)

- Not a real macOS `.saver` screensaver bundle. Plain `.app` only.
- No settings UI, hotkeys (besides `Esc`/`Cmd+Q`), pause, or speed control.
- No multi-monitor support (main display only).
- No app icon, code signing, or notarization in MVP.
- No unit tests — acceptance is visual.

## Approach

**SwiftUI app shell + Metal fragment shader.**

Rejected alternatives:

- SwiftUI `Canvas` with marching squares: clean code, but CPU-bound; will not sustain 60 fps at 5K.
- `CAShapeLayer` with procedurally generated paths: even slower, more complex.

Metal is the idiomatic GPU path for shadertoy-style isoline rendering, ~50 lines of shader. CPU does only the per-frame uniform update.

## Architecture

```
WokyisScreensaverApp.swift   @main, WindowGroup, triggers fullscreen on appear, installs Esc handler
ContentView.swift            hosts MetalView
MetalView.swift              NSViewRepresentable wrapping MTKView; configures device, format, delegate
Renderer.swift               MTKViewDelegate; owns pipeline state, drives draws, updates time uniform
Shaders.metal                full-screen vertex shader + fragment shader (simplex noise + contours)
```

Each unit has one responsibility:

- **App** sets up window and global key handling. Knows nothing about Metal.
- **MetalView** is a thin bridge from SwiftUI to AppKit/MTKView. Knows nothing about shader internals.
- **Renderer** owns the GPU pipeline and per-frame state. Knows nothing about SwiftUI.
- **Shaders.metal** is pure GPU code; everything visual lives here.

## Rendering Pipeline

- Single draw call per frame: full-screen triangle (3 vertices generated in the vertex shader from `vertex_id`, no vertex buffer).
- Fragment shader receives `uv` (from interpolated clip-space coords) and a uniforms struct.
- Color format: `.bgra8Unorm`. Clear color: black.

### Uniforms

```
struct Uniforms {
    float2 viewportSize;  // points * scale, in pixels
    float  time;          // seconds since launch
};
```

Updated each frame in `Renderer.draw(in:)` from a monotonic clock.

### Fragment shader logic

```
uv = (position.xy / viewportSize) - 0.5
uv.x *= viewportSize.x / viewportSize.y   // aspect-correct
n = simplexNoise3D(uv * SCALE, time * SPEED)
bands = fract(n * LINE_COUNT) - 0.5
aa = fwidth(bands)
core  = 1 - smoothstep(THICKNESS * aa, (THICKNESS + SOFTNESS) * aa, abs(bands))
halo  = 1 - smoothstep((THICKNESS + SOFTNESS) * aa, (THICKNESS + SOFTNESS + HALO) * aa, abs(bands))
color = mix(black, gray, halo) ; color = mix(color, white, core)
```

Tunable constants (start values, adjust visually):

| Constant     | Value | Meaning                          |
|--------------|-------|----------------------------------|
| `SCALE`      | 2.5   | Pattern size (lower = bigger)    |
| `LINE_COUNT` | 8.0   | Number of isolines               |
| `SPEED`      | 0.10  | Time multiplier                  |
| `THICKNESS`  | 1.0   | Core line width (in aa units)    |
| `SOFTNESS`   | 1.5   | Core line softness               |
| `HALO`       | 2.0   | Outer gray halo extent           |

Simplex noise: standard public-domain 3D simplex implementation (Ashima/Stefan Gustavson port), inlined into `Shaders.metal`.

## Window & Input

- `WindowGroup { ContentView() }` with `.windowStyle(.hiddenTitleBar)` and `.windowResizability(.contentSize)`.
- On first appear, call `NSApp.windows.first?.toggleFullScreen(nil)` to enter native fullscreen (menu bar + dock hide automatically).
- Global key monitor via `NSEvent.addLocalMonitorForEvents(matching: .keyDown)`: on `Esc` (keyCode 53), call `NSApp.terminate(nil)`.
- `Cmd+Q` works out of the box via default app menu.
- Mouse clicks: ignored.
- Default `MainMenu` (Apple + App menu) — no custom menus.
- App Sandbox: disabled. Hardened runtime: default Xcode template.

## Project Layout

```
WokyisScreensaver.xcodeproj
WokyisScreensaver/
    WokyisScreensaverApp.swift
    ContentView.swift
    MetalView.swift
    Renderer.swift
    Shaders.metal
    Info.plist (minimal, app category: graphics)
    Assets.xcassets/ (empty AccentColor, AppIcon placeholder)
```

Bundle identifier: `ai.unreallabs.wokyis-screensaver` (placeholder; can change).
Deployment target: macOS 14 (anything that supports current SwiftUI and Metal is fine).

## Acceptance Criteria

1. Open the project in Xcode → Cmd+R → window opens and goes fullscreen on the main display.
2. Visible: smoothly evolving white isolines with subtle gray edges on a solid black background. Pattern visibly resembles the reference image.
3. No noticeable hitches; activity monitor reports the renderer pegged at the display refresh rate.
4. Pressing `Esc` exits the app immediately. `Cmd+Q` also exits.
5. No crashes during a 5-minute idle run.

## Risks / Open Items

- **Visual tuning:** the six constants above will need a tuning pass. Plan should reserve time for one round of visual iteration after the first runnable build.
- **Simplex noise implementation:** picking a permissively-licensed port and inlining it in `Shaders.metal` (no Swift Package).
- **Fullscreen-on-launch UX:** native fullscreen has a ~0.5s transition animation. Acceptable for MVP; can be replaced with borderless `.fullScreen` style later if needed.
