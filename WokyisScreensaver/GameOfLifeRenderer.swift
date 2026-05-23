import MetalKit
import simd

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
    private let pipelineState: MTLRenderPipelineState
    private let config: GoLConfig

    private var palette: Palette
    private var engine: GameOfLifeEngine!
    private var gridTexture: MTLTexture!
    private var uploadBuffer: [UInt8] = []
    private var cols: Int = 0
    private var rows: Int = 0
    private var lastStepTime: CFTimeInterval = CACurrentMediaTime()
    private var lastReseedTick: Int = 0
    private var viewportSize: SIMD2<Float> = .zero

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
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vert
        descriptor.fragmentFunction = frag
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("GoL pipeline state failed: \(error)")
        }

        super.init()

        // Bootstrap with a placeholder grid; the real size is set on first drawableSizeWillChange.
        rebuildGrid(cols: config.cols, rows: max(1, Int(Double(config.cols) * 9.0 / 16.0)))
    }

    func setPalette(_ palette: Palette) {
        self.palette = palette
    }

    func applyReseedIfNeeded(tick: Int) {
        guard tick != lastReseedTick else { return }
        lastReseedTick = tick
        engine.reseed()
        uploadState(engine.current, to: gridTexture)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = SIMD2<Float>(Float(size.width), Float(size.height))
        // Derive rows so cells are visually square: aspect of the viewport drives rows/cols ratio.
        let w = max(size.width, 1)
        let h = max(size.height, 1)
        let desiredCols = config.cols
        let desiredRows = max(1, Int((Double(desiredCols) * h / w).rounded()))
        if desiredRows != rows {
            rebuildGrid(cols: desiredCols, rows: desiredRows)
        }
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let stepInterval = 1.0 / config.stepsPerSec
        let elapsed = now - lastStepTime
        if elapsed >= stepInterval {
            let stepsNeeded = min(Int(elapsed / stepInterval), 3)
            for _ in 0..<stepsNeeded {
                engine.step()
            }
            lastStepTime = now
            uploadState(engine.current, to: gridTexture)
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
            colorA: palette.colorA,
            colorB: palette.colorB,
            cellInset: 0.07
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<GoLUniforms>.stride, index: 0)
        encoder.setFragmentTexture(gridTexture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func rebuildGrid(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
        let texDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: cols,
            height: rows,
            mipmapped: false
        )
        texDesc.usage = .shaderRead
        texDesc.storageMode = .shared
        guard let t = device.makeTexture(descriptor: texDesc) else {
            fatalError("Failed to allocate grid texture")
        }
        self.gridTexture = t
        self.engine = GameOfLifeEngine(cols: cols, rows: rows, config: config)
        self.uploadBuffer = [UInt8](repeating: 0, count: cols * rows * 4)
        uploadState(engine.current, to: gridTexture)
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
