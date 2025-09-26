import Foundation
import Metal
import MetalKit
import simd

final class Renderer: NSObject, MTKViewDelegate {

    // MARK: - Metal
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private var pipeline: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var paramsBuffer: MTLBuffer!

    // MARK: - Time
    private var startTime: CFTimeInterval = CACurrentMediaTime()

    // MARK: - Incoming UI params
    /// Latest values pushed from SwiftUI each frame.
    /// IMPORTANT: This implementation animates ONLY when a scent is added or removed.
    /// Slider changes are applied immediately (no tween).
    var uiParams = ShaderParams() {
        didSet {
            // 1) Scale tween (unchanged)
            if uiParams.scale != targetScale {
                scaleFrom = currentScale
                targetScale = uiParams.scale
                scaleAnimStart = CACurrentMediaTime()
                scaleAnimating = true
            }

            // 2) Snapshot new UI state
            let newColors: [SIMD4<Float>] = [
                uiParams.color1, uiParams.color2, uiParams.color3,
                uiParams.color4, uiParams.color5, uiParams.color6
            ]
            let newMasks: [Float] = [
                uiParams.mask1, uiParams.mask2, uiParams.mask3,
                uiParams.mask4, uiParams.mask5, uiParams.mask6
            ]
            let newIntensities: [Float] = [
                uiParams.intensity1, uiParams.intensity2, uiParams.intensity3,
                uiParams.intensity4, uiParams.intensity5, uiParams.intensity6
            ]

            // Always update targets from UI (sliders are immediate)
            for i in 0..<6 { targetIntensity[i] = newIntensities[i] }

            // 3) ADD detection
            // Preferred: explicit pulse via uiParams.addedIndex (0...5), else fallback to mask rising edge.
            var handledAddIndex: Int? = nil
            if let added = getOptionalIndex(from: uiParams, key: "addedIndex"), added >= 0 && added < 6 {
                if added != lastAddedIndex {
                    startFadeIn(at: Int(added), to: newIntensities[Int(added)])
                }
                lastAddedIndex = added
                handledAddIndex = Int(added)
            } else {
                lastAddedIndex = -1
            }
            if handledAddIndex == nil {
                for i in 0..<6 {
                    if prevMasks[i] <= 0.0 && newMasks[i] > 0.0 {
                        // Mask rose 0->1: treat as an "add"
                        startFadeIn(at: i, to: newIntensities[i])
                    }
                }
            }

            // 4) REMOVE detection
            // Preferred: explicit pulse via uiParams.removedIndex (0...5), else fallback to mask falling edge.
            var handledRemoveIndex: Int? = nil
            if let removed = getOptionalIndex(from: uiParams, key: "removedIndex"), removed >= 0 && removed < 6 {
                if removed != lastRemovedIndex {
                    startFadeOutGhost(at: Int(removed),
                                      color: prevColors[Int(removed)],
                                      from: currentIntensity[Int(removed)])
                }
                lastRemovedIndex = removed
                handledRemoveIndex = Int(removed)
            } else {
                lastRemovedIndex = -1
            }
            if handledRemoveIndex == nil {
                for i in 0..<6 {
                    if prevMasks[i] > 0.0 && newMasks[i] <= 0.0 {
                        // Mask fell 1->0: treat as a "remove"
                        startFadeOutGhost(at: i,
                                          color: prevColors[i],
                                          from: currentIntensity[i])
                    }
                }
            }

            // 5) Update previous snapshot for next diff
            prevColors = newColors
            prevMasks  = newMasks
            prevIntens = newIntensities
        }
    }

    // MARK: - Scale tween (3s)
    private var currentScale: Float = 1.0
    private var targetScale:  Float = 1.0
    private var scaleFrom:    Float = 1.0
    private var scaleAnimStart: CFTimeInterval = CACurrentMediaTime()
    private let scaleAnimDuration: CFTimeInterval = 3.0
    private var scaleAnimating: Bool = false

    // MARK: - Intensity (add) fade tween
    private var currentIntensity: [Float] = Array(repeating: 1, count: 6)
    private var targetIntensity:  [Float] = Array(repeating: 1, count: 6)
    private var fromIntensity:    [Float] = Array(repeating: 1, count: 6)
    private var intensityAnimStart: [CFTimeInterval] = Array(repeating: CACurrentMediaTime(), count: 6)
    private var intensityAnimating:  [Bool] = Array(repeating: false, count: 6)
    private let intensityAnimDuration: CFTimeInterval = 2.0 // match scale
    private var lastAddedIndex: Int32 = -1

    // MARK: - Removal "ghost" fade-out
    private var ghostActive:   [Bool] = Array(repeating: false, count: 6)
    private var ghostColor:    [SIMD4<Float>] = Array(repeating: SIMD4<Float>(0,0,0,1), count: 6)
    private var ghostFrom:     [Float] = Array(repeating: 0, count: 6)
    private var ghostValue:    [Float] = Array(repeating: 0, count: 6) // animated intensity
    private var ghostAnimStart:[CFTimeInterval] = Array(repeating: CACurrentMediaTime(), count: 6)
    private let ghostAnimDuration: CFTimeInterval = 2.0 // match scale / intensity
    private var lastRemovedIndex: Int32 = -1

    // MARK: - Previous UI snapshot (for diffing)
    private var prevColors: [SIMD4<Float>] = Array(repeating: SIMD4<Float>(0,0,0,1), count: 6)
    private var prevMasks:  [Float] = Array(repeating: 0, count: 6)
    private var prevIntens: [Float] = Array(repeating: 1, count: 6)

    // MARK: - View size
    private var drawableSize: CGSize = .zero

    init(mtkView: MTKView) {
        guard let dev = MTLCreateSystemDefaultDevice(),
              let q = dev.makeCommandQueue() else {
            fatalError("Metal unavailable")
        }
        
        
        device = dev
        
        queue  = q
        super.init()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly  = true
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.delegate = self

        buildPipeline(mtkView: mtkView)
        buildBuffers()

        // Seed snapshots from initial UI values
        prevColors = [
            uiParams.color1, uiParams.color2, uiParams.color3,
            uiParams.color4, uiParams.color5, uiParams.color6
        ]
        prevMasks  = [
            uiParams.mask1, uiParams.mask2, uiParams.mask3,
            uiParams.mask4, uiParams.mask5, uiParams.mask6
        ]
        prevIntens = [
            uiParams.intensity1, uiParams.intensity2, uiParams.intensity3,
            uiParams.intensity4, uiParams.intensity5, uiParams.intensity6
        ]
        targetIntensity  = prevIntens
        currentIntensity = prevIntens
        fromIntensity    = prevIntens
    }

    private func buildPipeline(mtkView: MTKView) {
        let library = try! device.makeDefaultLibrary(bundle: .main)
        let vfn = library.makeFunction(name: "vertex_main")!
        let ffn = library.makeFunction(name: "fragment_main")!

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vfn
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

        // ---- Time
        let now = CACurrentMediaTime()
        let t = Float(now - startTime)

        // ---- Scale tween
        if scaleAnimating {
            let elapsed = now - scaleAnimStart
            let norm = min(max(elapsed / scaleAnimDuration, 0.0), 1.0)
            let eased = easeInOut(norm)
            currentScale = mix(scaleFrom, targetScale, Float(eased))
            if norm >= 1.0 { scaleAnimating = false }
        } else {
            currentScale = targetScale
        }

        // ---- Intensity fade-in (on add)
        for i in 0..<6 {
            if intensityAnimating[i] {
                let elapsed = now - intensityAnimStart[i]
                let norm = min(max(elapsed / intensityAnimDuration, 0.0), 1.0)
                let eased = easeInOut(norm)
                currentIntensity[i] = mix(fromIntensity[i], targetIntensity[i], Float(eased))
                if norm >= 1.0 { intensityAnimating[i] = false }
            } else {
                // Immediate response (sliders)
                currentIntensity[i] = targetIntensity[i]
            }
        }

        // ---- Ghost fade-out (on remove)
        for i in 0..<6 where ghostActive[i] {
            let elapsed = now - ghostAnimStart[i]
            let norm = min(max(elapsed / ghostAnimDuration, 0.0), 1.0)
            let eased = easeInOut(norm)
            ghostValue[i] = mix(ghostFrom[i], 0.0, Float(eased))
            if norm >= 1.0 {
                ghostActive[i] = false
                ghostValue[i] = 0.0
            }
        }

        // ---- Pack params (with ghost overrides)
        var gp = GPUParams()
        gp.time       = t
        gp.speed      = uiParams.speed
        gp.scale      = currentScale
        gp.warp       = uiParams.warp
        gp.edge       = uiParams.edge
        gp.separation = uiParams.separation
        gp.contrast   = uiParams.contrast

        if drawableSize.width > 0, drawableSize.height > 0 {
            let aspect = Float(drawableSize.width / max(1.0, drawableSize.height))
            gp.aspect = SIMD2(aspect, 1)
        }

        // Start with UI-provided colors/masks
        var colors: [SIMD4<Float>] = [
            uiParams.color1, uiParams.color2, uiParams.color3,
            uiParams.color4, uiParams.color5, uiParams.color6
        ]
        var masks: [Float] = [
            uiParams.mask1, uiParams.mask2, uiParams.mask3,
            uiParams.mask4, uiParams.mask5, uiParams.mask6
        ]
        var intens: [Float] = [
            currentIntensity[0], currentIntensity[1], currentIntensity[2],
            currentIntensity[3], currentIntensity[4], currentIntensity[5]
        ]

        // Apply ghost overrides (keep visible while fading out)
        for i in 0..<6 where ghostActive[i] {
            colors[i]  = ghostColor[i]
            intens[i]  = ghostValue[i]
            masks[i]   = 1.0 // force visible during fade-out
        }

        // Copy into struct
        gp.color1 = colors[0]; gp.color2 = colors[1]; gp.color3 = colors[2]
        gp.color4 = colors[3]; gp.color5 = colors[4]; gp.color6 = colors[5]

        gp.mask1 = masks[0]; gp.mask2 = masks[1]; gp.mask3 = masks[2]
        gp.mask4 = masks[3]; gp.mask5 = masks[4]; gp.mask6 = masks[5]

        gp.intensity1 = intens[0]; gp.intensity2 = intens[1]; gp.intensity3 = intens[2]
        gp.intensity4 = intens[3]; gp.intensity5 = intens[4]; gp.intensity6 = intens[5]

        // Upload & draw
        memcpy(paramsBuffer.contents(), &gp, MemoryLayout<GPUParams>.stride)

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
    private func startFadeIn(at i: Int, to target: Float) {
        fromIntensity[i]      = 0.0
        currentIntensity[i]   = 0.0
        targetIntensity[i]    = target
        intensityAnimStart[i] = CACurrentMediaTime()
        intensityAnimating[i] = true
    }

    private func startFadeOutGhost(at i: Int, color: SIMD4<Float>, from: Float) {
        ghostActive[i]    = true
        ghostColor[i]     = color
        ghostFrom[i]      = max(0.0, from)
        ghostValue[i]     = ghostFrom[i]
        ghostAnimStart[i] = CACurrentMediaTime()
    }

    /// Returns an optional Int32 field from `uiParams` by name, if present.
    /// This allows the Renderer to compile even if your ShaderParams doesn't yet
    /// declare `addedIndex` or `removedIndex`. If not present, returns nil.
    private func getOptionalIndex(from params: ShaderParams, key: String) -> Int32? {
        // Try to access via Mirror; falls back to nil if not present
        let m = Mirror(reflecting: params)
        for child in m.children {
            if child.label == key {
                if let v = child.value as? Int32 { return v }
                if let v = child.value as? Int { return Int32(v) }
                if let v = child.value as? UInt32 { return Int32(bitPattern: v) }
            }
        }
        return nil
    }

    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
    private func easeInOut(_ x: Double) -> Double {
        // classic smoothstep-ish
        return x < 0.5 ? 2*x*x : 1 - pow(-2*x + 2, 2)/2
    }
}
