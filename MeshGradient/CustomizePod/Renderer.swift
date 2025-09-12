import Foundation
import Metal
import MetalKit
import simd

final class Renderer: NSObject, MTKViewDelegate {

    // MARK: Metal
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private var pipeline: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var paramsBuffer: MTLBuffer!

    // MARK: Time
    private var startTime: CFTimeInterval = CACurrentMediaTime()

    // MARK: UI params (latest from SwiftUI)
    var uiParams = ShaderParams() {
        didSet {
            // Detect target scale change to launch a new tween
            if uiParams.scale != targetScale {
                scaleFrom = currentScale
                targetScale = uiParams.scale
                scaleAnimStart = CACurrentMediaTime()
                scaleAnimating = true
            }
        }
    }

    // MARK: Scale tween (3 seconds)
    private var currentScale: Float = 1.0
    private var targetScale:  Float = 1.0
    private var scaleFrom:    Float = 1.0
    private var scaleAnimStart: CFTimeInterval = CACurrentMediaTime()
    private let scaleAnimDuration: CFTimeInterval = 3.0
    private var scaleAnimating: Bool = false

    // MARK: View size
    private var drawableSize: CGSize = .zero

    init(mtkView: MTKView) {
        guard let dev = MTLCreateSystemDefaultDevice(),
              let q = dev.makeCommandQueue() else {
            fatalError("Metal unavailable")
        }
        device = dev
        queue = q
        super.init()

        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = true
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.delegate = self

        buildPipeline(mtkView: mtkView)
        buildBuffers()
    }

    private func buildPipeline(mtkView: MTKView) {
        let library = try! device.makeDefaultLibrary(bundle: .main)
        let vfn = library.makeFunction(name: "vertex_main")!
        let ffn = library.makeFunction(name: "fragment_main")!

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction   = vfn
        desc.fragmentFunction = ffn
        desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipeline = try! device.makeRenderPipelineState(descriptor: desc)
    }

    private func buildBuffers() {
        // Fullscreen quad (NDC)
        let quad: [SIMD2<Float>] = [
            SIMD2(-1, -1), SIMD2( 1, -1), SIMD2(-1,  1),
            SIMD2( 1, -1), SIMD2( 1,  1), SIMD2(-1,  1),
        ]
        vertexBuffer = device.makeBuffer(bytes: quad,
                                         length: MemoryLayout<SIMD2<Float>>.stride * quad.count,
                                         options: .storageModeShared)
        paramsBuffer = device.makeBuffer(length: MemoryLayout<GPUParams>.stride,
                                         options: .storageModeShared)
    }

    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawableSize = size
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor else { return }

        // ---- Update time
        let now = CACurrentMediaTime()
        let t = Float(now - startTime)

        // ---- Update scale (tween over 3 seconds)
        if scaleAnimating {
            let elapsed = now - scaleAnimStart
            let norm = min(max(elapsed / scaleAnimDuration, 0.0), 1.0)
            // smooth easing
            let eased = easeInOut(norm)
            currentScale = mix(scaleFrom, targetScale, Float(eased))
            if norm >= 1.0 { scaleAnimating = false }
        } else {
            currentScale = targetScale
        }

        // ---- Pack params
        var gp = GPUParams()
        gp.time       = t
        gp.speed      = uiParams.speed
        gp.scale      = currentScale          // <-- animated value fed to shader
        gp.warp       = uiParams.warp
        gp.edge       = uiParams.edge
        gp.separation = uiParams.separation
        gp.contrast   = uiParams.contrast

        if drawableSize.width > 0, drawableSize.height > 0 {
            let aspect = Float(drawableSize.width / max(1.0, drawableSize.height))
            gp.aspect = SIMD2(aspect, 1)
        }

        gp.color1 = uiParams.color1; gp.color2 = uiParams.color2; gp.color3 = uiParams.color3
        gp.color4 = uiParams.color4; gp.color5 = uiParams.color5; gp.color6 = uiParams.color6

        gp.mask1 = uiParams.mask1; gp.mask2 = uiParams.mask2; gp.mask3 = uiParams.mask3
        gp.mask4 = uiParams.mask4; gp.mask5 = uiParams.mask5; gp.mask6 = uiParams.mask6

        gp.intensity1 = uiParams.intensity1; gp.intensity2 = uiParams.intensity2; gp.intensity3 = uiParams.intensity3
        gp.intensity4 = uiParams.intensity4; gp.intensity5 = uiParams.intensity5; gp.intensity6 = uiParams.intensity6

        // Copy to GPU
        memcpy(paramsBuffer.contents(), &gp, MemoryLayout<GPUParams>.stride)

        // ---- Encode
        let cmd = queue.makeCommandBuffer()!
        let enc = cmd.makeRenderCommandEncoder(descriptor: rpd)!
        enc.setRenderPipelineState(pipeline)
        enc.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        enc.setFragmentBuffer(paramsBuffer, offset: 0, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        enc.endEncoding()
        cmd.present(drawable)
        cmd.commit()
    }

    // MARK: - Helpers
    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
    private func easeInOut(_ x: Double) -> Double {
        // classic smoothstep-ish ease
        return x < 0.5 ? 2*x*x : 1 - pow(-2*x + 2, 2)/2
    }
}
