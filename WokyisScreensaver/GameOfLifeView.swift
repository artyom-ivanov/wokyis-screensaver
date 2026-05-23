import SwiftUI
import MetalKit

struct GameOfLifeView: NSViewRepresentable {
    var config: GoLConfig = GoLConfig()

    func makeCoordinator() -> GameOfLifeRenderer {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        // We don't know the view aspect at coordinator-creation time. Pick rows from
        // the spec's 16:9 default; once the view sizes, the texture stays fixed —
        // the grid logic doesn't depend on viewport pixels, only the visual stretch.
        let cols = config.cols
        let rows = Int((Double(cols) * 9.0 / 16.0).rounded())
        return GameOfLifeRenderer(device: device,
                                  pixelFormat: .bgra8Unorm,
                                  cols: cols,
                                  rows: rows,
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
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}
