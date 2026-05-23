# Wokyis Screensaver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal fullscreen macOS app that renders smoothly animated white topographic-style contour lines on a black background, driven by a Metal fragment shader on a 3D simplex-noise field.

**Architecture:** SwiftUI `@main` app shell containing an `MTKView` (wrapped via `NSViewRepresentable`). A `Renderer` (MTKViewDelegate) drives one full-screen-triangle draw call per frame. A single Metal fragment shader samples 3D simplex noise and converts it to antialiased isolines with a subtle gray halo. The Xcode project is generated from `project.yml` via xcodegen so the repo stays clean.

**Tech Stack:** Swift 6, SwiftUI, AppKit (NSEvent / NSApplication), Metal / MetalKit, xcodegen, xcodebuild.

**Verification strategy:** This is a visual app — there are no meaningful unit tests for a fragment shader. Each task uses two checks: (1) `xcodebuild build` succeeds (catches syntax/linker errors); (2) a described visual check the human runs by hitting Cmd+R in Xcode. The plan calls out exactly what to see at each phase.

---

## File Structure

Files created across the plan (in build order):

| File | Responsibility |
|------|---------------|
| `project.yml` | xcodegen config — generates the `.xcodeproj` |
| `.gitignore` | Excludes generated `.xcodeproj`, `DerivedData`, `.DS_Store` |
| `WokyisScreensaver/WokyisScreensaverApp.swift` | `@main` entry; window setup; fullscreen + Esc wiring |
| `WokyisScreensaver/ContentView.swift` | Top-level view; hosts MetalView |
| `WokyisScreensaver/MetalView.swift` | `NSViewRepresentable` wrapping MTKView; configures device, format, delegate |
| `WokyisScreensaver/Renderer.swift` | `MTKViewDelegate`; pipeline state, per-frame draws, time/viewport uniforms |
| `WokyisScreensaver/Shaders.metal` | Vertex shader (3-vertex fullscreen triangle) + fragment shader (simplex noise → isolines + halo) |
| `WokyisScreensaver/Info.plist` | App metadata (bundle id, category, no LSUIElement) |
| `WokyisScreensaver/Assets.xcassets/Contents.json` | Asset catalog root (empty; required by Xcode template conventions) |

Each unit has one responsibility; no Swift file references shader internals and no Metal file knows about SwiftUI.

---

## Task 1: Bootstrap project and verify empty SwiftUI app builds

**Goal:** Repo can be opened in Xcode, builds clean, runs a window showing a solid color. No Metal yet.

**Files:**
- Create: `project.yml`
- Create: `.gitignore`
- Create: `WokyisScreensaver/WokyisScreensaverApp.swift`
- Create: `WokyisScreensaver/ContentView.swift`
- Create: `WokyisScreensaver/Info.plist`
- Create: `WokyisScreensaver/Assets.xcassets/Contents.json`

- [ ] **Step 1: Write `.gitignore`**

```
.DS_Store
DerivedData/
build/
*.xcodeproj/
!project.yml
*.xcuserstate
xcuserdata/
```

- [ ] **Step 2: Write `project.yml`**

```yaml
name: WokyisScreensaver
options:
  bundleIdPrefix: ai.unreallabs
  deploymentTarget:
    macOS: "14.0"
  developmentLanguage: en
settings:
  base:
    SWIFT_VERSION: "6.0"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
targets:
  WokyisScreensaver:
    type: application
    platform: macOS
    sources:
      - path: WokyisScreensaver
    info:
      path: WokyisScreensaver/Info.plist
      properties:
        CFBundleName: WokyisScreensaver
        CFBundleDisplayName: Wokyis Screensaver
        LSApplicationCategoryType: public.app-category.graphics-design
        NSHumanReadableCopyright: ""
        NSPrincipalClass: NSApplication
        NSMainStoryboardFile: ""
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: ai.unreallabs.wokyis-screensaver
        ENABLE_HARDENED_RUNTIME: YES
        CODE_SIGN_STYLE: Automatic
        CODE_SIGN_IDENTITY: "-"
        ENABLE_APP_SANDBOX: NO
        GENERATE_INFOPLIST_FILE: NO
        MTL_FAST_MATH: YES
```

- [ ] **Step 3: Write `WokyisScreensaver/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Write `WokyisScreensaver/Assets.xcassets/Contents.json`**

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 5: Write `WokyisScreensaver/WokyisScreensaverApp.swift`**

```swift
import SwiftUI

@main
struct WokyisScreensaverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
```

- [ ] **Step 6: Write `WokyisScreensaver/ContentView.swift`**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
    }
}
```

- [ ] **Step 7: Generate the Xcode project**

Run: `xcodegen generate`
Expected: `Generated project successfully` and `WokyisScreensaver.xcodeproj` appears.

- [ ] **Step 8: Build via xcodebuild**

Run: `xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0, no errors.

- [ ] **Step 9: Visual check**

Open `WokyisScreensaver.xcodeproj` in Xcode, press Cmd+R.
Expected: a window appears with a solid black interior, no title bar text. Close the window or Cmd+Q to exit.

- [ ] **Step 10: Commit**

```bash
git add .gitignore project.yml WokyisScreensaver/
git commit -m "scaffold SwiftUI app + xcodegen project"
```

---

## Task 2: Add MTKView wired through MetalView + Renderer

**Goal:** Replace the black `Color` view with a `MetalView` backed by an `MTKView`. `Renderer` does nothing yet except set a non-black clear color (so we can confirm the Metal view is actually drawing).

**Files:**
- Create: `WokyisScreensaver/MetalView.swift`
- Create: `WokyisScreensaver/Renderer.swift`
- Modify: `WokyisScreensaver/ContentView.swift`

- [ ] **Step 1: Write `Renderer.swift`**

```swift
import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    private let commandQueue: MTLCommandQueue

    init(device: MTLDevice) {
        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = queue
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
```

- [ ] **Step 2: Write `MetalView.swift`**

```swift
import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {
    func makeCoordinator() -> Renderer {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        return Renderer(device: device)
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 1.0)
        view.framebufferOnly = true
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 120
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}
```

- [ ] **Step 3: Replace contents of `ContentView.swift`**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        MetalView()
            .ignoresSafeArea()
    }
}
```

- [ ] **Step 4: Regenerate Xcode project**

Run: `xcodegen generate`
Expected: `Generated project successfully`.

- [ ] **Step 5: Build**

Run: `xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0.

- [ ] **Step 6: Visual check**

Cmd+R in Xcode. Window should show a solid teal/cyan color (the clear color we set). This confirms `MTKView` is allocating drawables and `Renderer.draw` is presenting them. Close the window.

- [ ] **Step 7: Commit**

```bash
git add WokyisScreensaver/MetalView.swift WokyisScreensaver/Renderer.swift WokyisScreensaver/ContentView.swift
git commit -m "wire MTKView through SwiftUI with stub renderer"
```

---

## Task 3: Add fullscreen-triangle vertex shader + UV gradient fragment shader

**Goal:** Make `Shaders.metal`, build a render pipeline state in `Renderer`, and issue one draw call per frame that renders a UV gradient (red = u, green = v) covering the screen. Confirms the shader pipeline is end-to-end functional.

**Files:**
- Create: `WokyisScreensaver/Shaders.metal`
- Modify: `WokyisScreensaver/Renderer.swift`

- [ ] **Step 1: Write `Shaders.metal`**

```metal
#include <metal_stdlib>
using namespace metal;

struct VSOut {
    float4 position [[position]];
    float2 uv;
};

vertex VSOut vs_fullscreen(uint vid [[vertex_id]]) {
    // Three vertices form one large triangle covering the screen.
    // vid 0 -> (-1, -1), vid 1 -> (3, -1), vid 2 -> (-1, 3) in clip space.
    float2 p = float2((vid == 1) ? 3.0 : -1.0,
                      (vid == 2) ? 3.0 : -1.0);
    VSOut out;
    out.position = float4(p, 0.0, 1.0);
    // uv: 0..1 across the visible portion of the triangle.
    out.uv = (p + 1.0) * 0.5;
    return out;
}

fragment float4 fs_main(VSOut in [[stage_in]]) {
    return float4(in.uv.x, in.uv.y, 0.0, 1.0);
}
```

- [ ] **Step 2: Replace contents of `Renderer.swift`**

```swift
import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {
        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vs_fullscreen")
        descriptor.fragmentFunction = library.makeFunction(name: "fs_main")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
        self.device = device
        self.commandQueue = queue
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
```

- [ ] **Step 3: Update `MetalView.swift` to pass pixel format to Renderer**

Replace the `makeCoordinator` method with:

```swift
    func makeCoordinator() -> Renderer {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        return Renderer(device: device, pixelFormat: .bgra8Unorm)
    }
```

Also change `view.clearColor` in `makeNSView` to black (we'll see the gradient now, not the clear):

```swift
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
```

- [ ] **Step 4: Regenerate and build**

Run: `xcodegen generate && xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0, no errors. The `.metal` file is auto-detected by xcodegen because it's inside `WokyisScreensaver/`.

- [ ] **Step 5: Visual check**

Cmd+R. Window should show a smooth red→yellow→green→black gradient (red along x-axis, green along y-axis). Confirms vertex+fragment shaders both run.

- [ ] **Step 6: Commit**

```bash
git add WokyisScreensaver/Shaders.metal WokyisScreensaver/Renderer.swift WokyisScreensaver/MetalView.swift
git commit -m "add fullscreen-triangle pipeline rendering UV gradient"
```

---

## Task 4: Add uniforms (time + viewport size) and animate

**Goal:** Pass time and viewport-size uniforms from Swift to the fragment shader each frame. Modify the fragment to multiply the gradient by `(0.5 + 0.5*sin(time))` so we can visually confirm time is plumbed correctly.

**Files:**
- Modify: `WokyisScreensaver/Renderer.swift`
- Modify: `WokyisScreensaver/Shaders.metal`

- [ ] **Step 1: Add Uniforms struct at top of `Shaders.metal`**

Add immediately after `using namespace metal;`:

```metal
struct Uniforms {
    float2 viewportSize;
    float  time;
};
```

- [ ] **Step 2: Replace the fragment shader in `Shaders.metal`**

```metal
fragment float4 fs_main(VSOut in [[stage_in]],
                        constant Uniforms &u [[buffer(0)]]) {
    float pulse = 0.5 + 0.5 * sin(u.time);
    return float4(in.uv.x * pulse, in.uv.y * pulse, 0.0, 1.0);
}
```

- [ ] **Step 3: Replace `Renderer.swift` entirely**

```swift
import MetalKit
import simd

private struct Uniforms {
    var viewportSize: SIMD2<Float>
    var time: Float
}

final class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var viewportSize: SIMD2<Float> = .zero
    private let startTime: CFTimeInterval = CACurrentMediaTime()

    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {
        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vs_fullscreen")
        descriptor.fragmentFunction = library.makeFunction(name: "fs_main")
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
        self.device = device
        self.commandQueue = queue
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = SIMD2<Float>(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        var uniforms = Uniforms(
            viewportSize: viewportSize,
            time: Float(CACurrentMediaTime() - startTime)
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
```

- [ ] **Step 4: Build**

Run: `xcodegen generate && xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0.

- [ ] **Step 5: Visual check**

Cmd+R. Window should show the same red/green gradient but pulsing in brightness over a ~6.28-second cycle (sin wave). Confirms uniforms are flowing each frame.

- [ ] **Step 6: Commit**

```bash
git add WokyisScreensaver/Renderer.swift WokyisScreensaver/Shaders.metal
git commit -m "thread time + viewport uniforms from CPU to fragment"
```

---

## Task 5: Add 3D simplex noise and output as animated grayscale

**Goal:** Inline a well-known 3D simplex noise implementation (Ashima/Stefan Gustavson port, MIT-licensed) into `Shaders.metal` and have the fragment shader output `float3(n)` so we can see the noise field as evolving grayscale clouds.

**Files:**
- Modify: `WokyisScreensaver/Shaders.metal`

- [ ] **Step 1: Replace `Shaders.metal` in full with the noise implementation + grayscale fragment**

```metal
#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 viewportSize;
    float  time;
};

struct VSOut {
    float4 position [[position]];
    float2 uv;
};

vertex VSOut vs_fullscreen(uint vid [[vertex_id]]) {
    float2 p = float2((vid == 1) ? 3.0 : -1.0,
                      (vid == 2) ? 3.0 : -1.0);
    VSOut out;
    out.position = float4(p, 0.0, 1.0);
    out.uv = (p + 1.0) * 0.5;
    return out;
}

// --- 3D Simplex Noise -----------------------------------------------------
// Adapted from Ian McEwan / Ashima Arts / Stefan Gustavson "webgl-noise"
// (MIT license). Returns scalar in approximately [-1, 1].
static float3 mod289_3(float3 x) { return x - floor(x * (1.0/289.0)) * 289.0; }
static float4 mod289_4(float4 x) { return x - floor(x * (1.0/289.0)) * 289.0; }
static float4 permute(float4 x) { return mod289_4(((x*34.0)+1.0)*x); }
static float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(float3 v) {
    const float2 C = float2(1.0/6.0, 1.0/3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);

    float3 i  = floor(v + dot(v, C.yyy));
    float3 x0 = v   - i + dot(i, C.xxx);

    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + C.yyy;
    float3 x3 = x0 - D.yyy;

    i = mod289_3(i);
    float4 p = permute(permute(permute(
                 i.z + float4(0.0, i1.z, i2.z, 1.0))
               + i.y + float4(0.0, i1.y, i2.y, 1.0))
               + i.x + float4(0.0, i1.x, i2.x, 1.0));

    float n_ = 0.142857142857; // 1.0/7.0
    float3 ns = n_ * D.wyz - D.xzx;

    float4 j = p - 49.0 * floor(p * ns.z * ns.z);

    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);

    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0)*2.0 + 1.0;
    float4 s1 = floor(b1)*2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));

    float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);

    float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;

    float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, float4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}
// --- end simplex noise ----------------------------------------------------

constant float SCALE      = 2.5;
constant float SPEED      = 0.10;

fragment float4 fs_main(VSOut in [[stage_in]],
                        constant Uniforms &u [[buffer(0)]]) {
    float aspect = u.viewportSize.x / u.viewportSize.y;
    float2 p = in.uv - 0.5;
    p.x *= aspect;
    float n = snoise(float3(p * SCALE, u.time * SPEED));
    float g = 0.5 + 0.5 * n;
    return float4(g, g, g, 1.0);
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0.

- [ ] **Step 3: Visual check**

Cmd+R. Window should show smoothly animated grayscale "cloud" noise — blobs that slowly evolve and deform. No pulsing-gradient anymore. Confirms simplex noise compiles and animates.

- [ ] **Step 4: Commit**

```bash
git add WokyisScreensaver/Shaders.metal
git commit -m "render animated 3D simplex noise as grayscale"
```

---

## Task 6: Convert noise field to white isolines with gray halo

**Goal:** Replace grayscale output with the isoline formula from the spec: core white line + outer gray halo, both antialiased via `fwidth`. This is the visual target — animated white contour lines on black, with a subtle gray edge as in the reference image.

**Files:**
- Modify: `WokyisScreensaver/Shaders.metal`

- [ ] **Step 1: Add the rest of the tunable constants**

In `Shaders.metal`, replace the `constant float SCALE = 2.5;` / `constant float SPEED = 0.10;` lines with:

```metal
constant float SCALE      = 2.5;
constant float LINE_COUNT = 8.0;
constant float SPEED      = 0.10;
constant float THICKNESS  = 1.0;
constant float SOFTNESS   = 1.5;
constant float HALO       = 2.0;
constant float3 LINE_COLOR  = float3(1.0, 1.0, 1.0);
constant float3 HALO_COLOR  = float3(0.42, 0.42, 0.42);
constant float3 BG_COLOR    = float3(0.0, 0.0, 0.0);
```

- [ ] **Step 2: Replace the fragment shader body**

Replace the existing `fs_main` function with:

```metal
fragment float4 fs_main(VSOut in [[stage_in]],
                        constant Uniforms &u [[buffer(0)]]) {
    float aspect = u.viewportSize.x / u.viewportSize.y;
    float2 p = in.uv - 0.5;
    p.x *= aspect;

    float n = snoise(float3(p * SCALE, u.time * SPEED));
    float bands = fract(n * LINE_COUNT) - 0.5;
    float aa = fwidth(bands);

    float core = 1.0 - smoothstep(THICKNESS * aa,
                                  (THICKNESS + SOFTNESS) * aa,
                                  abs(bands));
    float halo = 1.0 - smoothstep((THICKNESS + SOFTNESS) * aa,
                                  (THICKNESS + SOFTNESS + HALO) * aa,
                                  abs(bands));

    float3 color = mix(BG_COLOR, HALO_COLOR, halo);
    color = mix(color, LINE_COLOR, core);
    return float4(color, 1.0);
}
```

- [ ] **Step 3: Build**

Run: `xcodegen generate && xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0.

- [ ] **Step 4: Visual check**

Cmd+R. Window should show smoothly animated **white contour lines on a black background**, with a subtle gray edge alongside each line. The pattern should visibly resemble the topographic reference image: closed loops, meandering curves, slowly deforming over time without ever repeating.

- [ ] **Step 5: Commit**

```bash
git add WokyisScreensaver/Shaders.metal
git commit -m "render isolines with antialiased core + halo"
```

---

## Task 7: Visual tuning pass

**Goal:** Adjust the six tunable constants until the output convincingly matches the reference image. This is a one-pass iteration: open the spec, open the reference image side-by-side with the running app, and tweak constants.

**Files:**
- Modify: `WokyisScreensaver/Shaders.metal`

- [ ] **Step 1: Compare against the reference image**

The reference shows:
- Medium-large loops (the largest features are ~⅓ of the screen width). If our `SCALE` produces patterns much smaller or larger, adjust `SCALE` down (smaller value = larger features) or up.
- 6–10 visible bands across the screen. If we have many more or fewer, adjust `LINE_COUNT`.
- Slow motion (continents-drifting slow, not flowing). If too fast, lower `SPEED`. If frozen, raise.
- Thin but clearly visible lines with a subtle gray edge. If lines too thick/thin, adjust `THICKNESS`. If halo too dark/bright, adjust `HALO_COLOR` brightness.

- [ ] **Step 2: Tweak constants in `Shaders.metal`**

Adjust the eight constants from Task 6 step 1 by editing values directly. Suggested tuning order: `SCALE` → `LINE_COUNT` → `SPEED` → `THICKNESS`/`SOFTNESS`/`HALO` → `HALO_COLOR`.

Rebuild and run after each change. There is no "correct" answer — match the reference by eye.

- [ ] **Step 3: Build to confirm no syntax errors**

Run: `xcodegen generate && xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0.

- [ ] **Step 4: Visual check**

Cmd+R. Output should visibly resemble the reference image to a reasonable degree (loop sizes, line density, motion speed). Don't chase pixel-perfect — get it close enough to look like the same family of visual.

- [ ] **Step 5: Commit**

```bash
git add WokyisScreensaver/Shaders.metal
git commit -m "tune shader constants to match reference"
```

---

## Task 8: Fullscreen on launch + Esc-to-quit handler

**Goal:** When the app launches, the window snaps into native macOS fullscreen automatically (menu bar + dock hide). Pressing `Esc` quits the app immediately.

**Files:**
- Modify: `WokyisScreensaver/WokyisScreensaverApp.swift`

- [ ] **Step 1: Replace `WokyisScreensaverApp.swift` with the fullscreen + Esc version**

```swift
import SwiftUI
import AppKit

@main
struct WokyisScreensaverApp: App {
    init() {
        installEscapeMonitor()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    DispatchQueue.main.async {
                        NSApp.windows.first?.toggleFullScreen(nil)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    private func installEscapeMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project WokyisScreensaver.xcodeproj -scheme WokyisScreensaver -configuration Debug build -quiet`
Expected: exit code 0.

- [ ] **Step 3: Visual check — fullscreen**

Cmd+R. After a brief (~0.5s) animation, the window expands to cover the entire display; the menu bar and dock are hidden. Animated white isolines fill the entire screen, no chrome visible.

- [ ] **Step 4: Visual check — Esc**

While in fullscreen, press `Esc`. The app should terminate immediately (window disappears, returns to desktop). Re-run with Cmd+R and confirm `Cmd+Q` also quits cleanly.

- [ ] **Step 5: Commit**

```bash
git add WokyisScreensaver/WokyisScreensaverApp.swift
git commit -m "enter fullscreen on launch; bind Esc to quit"
```

---

## Final Verification

After Task 8, run the full acceptance checklist from the spec:

1. ✅ Open the project in Xcode → Cmd+R → window opens and goes fullscreen on the main display.
2. ✅ Visible: smoothly evolving white isolines with subtle gray edges on a solid black background. Pattern resembles the reference image.
3. ✅ No noticeable hitches; smooth motion at native display refresh.
4. ✅ Pressing `Esc` exits the app immediately. `Cmd+Q` also exits.
5. ✅ No crashes during a 5-minute idle run.

If any check fails, the most likely culprits per check:

- (1) `toggleFullScreen` called before window exists → wrap in `DispatchQueue.main.async` (already done in Task 8).
- (2) Wrong shader constants → return to Task 7 and tune.
- (3) Vsync issue → confirm `view.preferredFramesPerSecond` and `view.isPaused = false` from Task 2.
- (4) Key monitor not installed → confirm `installEscapeMonitor()` is called in `App.init()` from Task 8.
- (5) Run for 5 minutes; if a crash occurs, attach a debugger and report the stack.
