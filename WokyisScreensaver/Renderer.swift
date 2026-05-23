import MetalKit
import simd

private struct Uniforms {
    var viewportSize: SIMD2<Float>
    var time: Float
}

final class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let startTime: CFTimeInterval = CACurrentMediaTime()

    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {
        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library")
        }
        guard let vert = library.makeFunction(name: "vs_fullscreen") else {
            fatalError("Shader function 'vs_fullscreen' not found in default Metal library")
        }
        guard let frag = library.makeFunction(name: "fs_main") else {
            fatalError("Shader function 'fs_main' not found in default Metal library")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vert
        descriptor.fragmentFunction = frag
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

        let size = view.drawableSize
        var uniforms = Uniforms(
            viewportSize: SIMD2<Float>(Float(size.width), Float(size.height)),
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
