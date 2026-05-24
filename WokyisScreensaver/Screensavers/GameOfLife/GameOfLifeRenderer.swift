import MetalKit
import simd

struct GoLConfig {
    var cols: Int = 200
    var stepsPerSec: Double = 20
    var density: Double = 0.15
    var trailDecay: UInt8 = 9
    var preEvolveSteps: Int = 6
}

private struct GoLUniforms {
    var gridSize: SIMD2<Float>
    var viewportSize: SIMD2<Float>
    var colorA: SIMD3<Float>
    var colorB: SIMD3<Float>
    var cellInset: Float
    var _pad0: Float = 0
    var _pad1: Float = 0
    var _pad2: Float = 0
}

final class GameOfLifeRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let renderPipeline: MTLRenderPipelineState
    private let stepPipeline: MTLComputePipelineState
    private let config: GoLConfig

    private var palette: Palette
    private var textureFront: MTLTexture!
    private var textureBack: MTLTexture!
    private var cols: Int = 0
    private var rows: Int = 0
    private var lastStepTime: CFTimeInterval = CACurrentMediaTime()
    private var lastReseedTick: Int = 0

    init(device: MTLDevice, pixelFormat: MTLPixelFormat, palette: Palette, config: GoLConfig) {
        self.device = device
        self.config = config
        self.palette = palette

        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create command queue")
        }
        self.commandQueue = queue

        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library")
        }
        guard let vert = library.makeFunction(name: "vs_gol") else {
            fatalError("Shader function 'vs_gol' not found")
        }
        guard let frag = library.makeFunction(name: "fs_gol") else {
            fatalError("Shader function 'fs_gol' not found")
        }
        guard let stepFn = library.makeFunction(name: "gol_step") else {
            fatalError("Compute function 'gol_step' not found")
        }

        let renderDesc = MTLRenderPipelineDescriptor()
        renderDesc.vertexFunction = vert
        renderDesc.fragmentFunction = frag
        renderDesc.colorAttachments[0].pixelFormat = pixelFormat
        do {
            self.renderPipeline = try device.makeRenderPipelineState(descriptor: renderDesc)
        } catch {
            fatalError("GoL render pipeline state failed: \(error)")
        }
        do {
            self.stepPipeline = try device.makeComputePipelineState(function: stepFn)
        } catch {
            fatalError("GoL compute pipeline state failed: \(error)")
        }

        super.init()
        rebuildGrid(cols: config.cols, rows: max(1, Int(Double(config.cols) * 9.0 / 16.0)))
    }

    func setPalette(_ palette: Palette) {
        self.palette = palette
    }

    func applyReseedIfNeeded(tick: Int) {
        guard tick != lastReseedTick else { return }
        lastReseedTick = tick
        reseed()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let w = max(size.width, 1)
        let h = max(size.height, 1)
        let desiredCols = config.cols
        let desiredRows = max(1, Int((Double(desiredCols) * h / w).rounded()))
        if desiredRows != rows {
            rebuildGrid(cols: desiredCols, rows: desiredRows)
        }
    }

    func draw(in view: MTKView) {
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }

        // Encode any due Conway steps into this frame's command buffer.
        let now = CACurrentMediaTime()
        let stepInterval = 1.0 / config.stepsPerSec
        let elapsed = now - lastStepTime
        if elapsed >= stepInterval {
            let stepsNeeded = min(Int(elapsed / stepInterval), 3)
            for _ in 0..<stepsNeeded {
                encodeStep(into: commandBuffer)
            }
            lastStepTime = now
        }

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            commandBuffer.commit()
            return
        }
        let size = view.drawableSize
        var uniforms = GoLUniforms(
            gridSize: SIMD2<Float>(Float(cols), Float(rows)),
            viewportSize: SIMD2<Float>(Float(size.width), Float(size.height)),
            colorA: palette.colorA,
            colorB: palette.colorB,
            cellInset: 0.07
        )
        encoder.setRenderPipelineState(renderPipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<GoLUniforms>.stride, index: 0)
        encoder.setFragmentTexture(textureFront, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func encodeStep(into cb: MTLCommandBuffer) {
        guard let encoder = cb.makeComputeCommandEncoder() else { return }
        encoder.setComputePipelineState(stepPipeline)
        encoder.setTexture(textureFront, index: 0)
        encoder.setTexture(textureBack, index: 1)
        var trailDecay = UInt32(config.trailDecay)
        encoder.setBytes(&trailDecay, length: MemoryLayout<UInt32>.size, index: 0)
        let tgWidth = stepPipeline.threadExecutionWidth
        let tgHeight = max(1, stepPipeline.maxTotalThreadsPerThreadgroup / tgWidth)
        let threadgroup = MTLSize(width: tgWidth, height: tgHeight, depth: 1)
        let gridSize = MTLSize(width: cols, height: rows, depth: 1)
        encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroup)
        encoder.endEncoding()
        swap(&textureFront, &textureBack)
    }

    private func rebuildGrid(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
        let texDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Uint,
            width: cols,
            height: rows,
            mipmapped: false
        )
        texDesc.usage = [.shaderRead, .shaderWrite]
        texDesc.storageMode = .shared
        guard let a = device.makeTexture(descriptor: texDesc),
              let b = device.makeTexture(descriptor: texDesc) else {
            fatalError("Failed to allocate grid textures")
        }
        self.textureFront = a
        self.textureBack = b
        reseed()
    }

    private func reseed() {
        // One-shot CPU random fill + GPU pre-evolve. Total work is ~22600 byte
        // writes on the CPU and `preEvolveSteps` compute passes on the GPU.
        let count = cols * rows
        var buf = [UInt8](repeating: 0, count: count * 4)
        for i in 0..<count {
            if Double.random(in: 0..<1) < config.density {
                buf[i * 4] = Bool.random() ? 1 : 2
            }
        }
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: cols, height: rows, depth: 1))
        buf.withUnsafeBufferPointer { ptr in
            textureFront.replace(region: region, mipmapLevel: 0,
                                 withBytes: ptr.baseAddress!,
                                 bytesPerRow: cols * 4)
        }
        guard let cb = commandQueue.makeCommandBuffer() else { return }
        for _ in 0..<config.preEvolveSteps {
            encodeStep(into: cb)
        }
        cb.commit()
        lastStepTime = CACurrentMediaTime()
    }
}
