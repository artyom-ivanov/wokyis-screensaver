import SwiftUI
import MetalKit

struct TopographicView: NSViewRepresentable {
    let settings: TopographicSettings

    func makeCoordinator() -> TopographicRenderer {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        return TopographicRenderer(device: device, pixelFormat: .bgra8Unorm, settings: settings)
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.device
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.framebufferOnly = true
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 120
        (view.layer as? CAMetalLayer)?.maximumDrawableCount = 2
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    static func dismantleNSView(_ nsView: MTKView, coordinator: TopographicRenderer) {
        nsView.releaseDrawables()
        nsView.delegate = nil
    }
}
