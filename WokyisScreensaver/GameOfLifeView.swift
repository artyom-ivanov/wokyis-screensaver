import SwiftUI
import MetalKit

struct GameOfLifeView: NSViewRepresentable {
    var palette: Palette
    var reseedTick: Int
    var config: GoLConfig = GoLConfig()

    func makeCoordinator() -> GameOfLifeRenderer {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        return GameOfLifeRenderer(device: device,
                                  pixelFormat: .bgra8Unorm,
                                  palette: palette,
                                  config: config)
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.device
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.framebufferOnly = true
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 30
        (view.layer as? CAMetalLayer)?.maximumDrawableCount = 2
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.setPalette(palette)
        context.coordinator.applyReseedIfNeeded(tick: reseedTick)
    }

    static func dismantleNSView(_ nsView: MTKView, coordinator: GameOfLifeRenderer) {
        nsView.releaseDrawables()
        nsView.delegate = nil
    }
}
