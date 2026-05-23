import MetalKit
import simd

private struct GoLUniforms {
    var gridSize: SIMD2<Float>
    var viewportSize: SIMD2<Float>
    var colorA: SIMD3<Float>
    var colorB: SIMD3<Float>
    var wipeProgress: Float
    var bandFraction: Float
    var cellInset: Float
    var _pad: Float = 0
}

final class GameOfLifeRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    private let engine: GameOfLifeEngine
    private let textureNew: MTLTexture
    private let textureOld: MTLTexture
    private var uploadBuffer: [UInt8]

    private let cols: Int
    private let rows: Int
    private var lastStepTime: CFTimeInterval = CACurrentMediaTime()

    private let colorA: SIMD3<Float>
    private let colorB: SIMD3<Float>
    private let config: GoLConfig

    init(device: MTLDevice, pixelFormat: MTLPixelFormat, cols: Int, rows: Int, config: GoLConfig) {
        self.device = device
        self.cols = cols
        self.rows = rows
        self.config = config

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
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vert
        descriptor.fragmentFunction = frag
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("GoL pipeline state failed: \(error)")
        }

        let texDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: cols,
            height: rows,
            mipmapped: false
        )
        texDesc.usage = .shaderRead
        texDesc.storageMode = .shared
        guard let tNew = device.makeTexture(descriptor: texDesc),
              let tOld = device.makeTexture(descriptor: texDesc) else {
            fatalError("Failed to allocate grid textures")
        }
        self.textureNew = tNew
        self.textureOld = tOld

        self.engine = GameOfLifeEngine(cols: cols, rows: rows, config: config)
        self.uploadBuffer = [UInt8](repeating: 0, count: cols * rows * 4)

        // Palette: Orange × Electric per spec defaults.
        self.colorA = SIMD3<Float>(1.0, 0x5E / 255.0, 0x16 / 255.0)
        self.colorB = SIMD3<Float>(0x1E / 255.0, 0x55 / 255.0, 1.0)

        super.init()

        uploadState(engine.current, to: textureNew)
        uploadState(engine.current, to: textureOld)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        // Advance the simulation in real time. Cap catch-up to avoid spirals when
        // the window loses focus and many step-intervals accumulate.
        let now = CACurrentMediaTime()
        let stepInterval = 1.0 / config.stepsPerSec
        let elapsed = now - lastStepTime
        if elapsed >= stepInterval {
            let stepsNeeded = min(Int(elapsed / stepInterval), 3)
            for _ in 0..<stepsNeeded {
                engine.step()
            }
            lastStepTime = now
            uploadState(engine.current, to: textureNew)
            if let oldState = engine.old {
                uploadState(oldState, to: textureOld)
            }
        }

        guard
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        let size = view.drawableSize
        var uniforms = GoLUniforms(
            gridSize: SIMD2<Float>(Float(cols), Float(rows)),
            viewportSize: SIMD2<Float>(Float(size.width), Float(size.height)),
            colorA: colorA,
            colorB: colorB,
            wipeProgress: engine.wipeProgress,
            bandFraction: config.wipeBandFraction,
            cellInset: 0.07
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<GoLUniforms>.stride, index: 0)
        encoder.setFragmentTexture(textureNew, index: 0)
        encoder.setFragmentTexture(engine.old != nil ? textureOld : textureNew, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func uploadState(_ s: GoLState, to texture: MTLTexture) {
        let count = cols * rows
        uploadBuffer.withUnsafeMutableBufferPointer { dst in
            s.state.withUnsafeBufferPointer { state in
                s.trail.withUnsafeBufferPointer { trail in
                    s.trailColor.withUnsafeBufferPointer { trailCol in
                        for i in 0..<count {
                            dst[i * 4]     = state[i]
                            dst[i * 4 + 1] = trail[i]
                            dst[i * 4 + 2] = trailCol[i]
                            dst[i * 4 + 3] = 0
                        }
                    }
                }
            }
        }
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: cols, height: rows, depth: 1))
        uploadBuffer.withUnsafeBufferPointer { ptr in
            texture.replace(region: region, mipmapLevel: 0,
                            withBytes: ptr.baseAddress!,
                            bytesPerRow: cols * 4)
        }
    }
}
