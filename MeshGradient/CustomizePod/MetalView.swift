// MetalView.swift
import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    var params: ShaderParams
    var paused: Bool = false   // ← new

    func makeUIView(context: Context) -> MTKView {
        let v = MTKView()
        v.device = MTLCreateSystemDefaultDevice()
        v.clearColor = MTLClearColorMake(0, 0, 0, 0)
        v.isOpaque = false
        v.framebufferOnly = false
        v.enableSetNeedsDisplay = false
        v.isPaused = paused      // ← respect initial paused state
        v.preferredFramesPerSecond = 30

        let r = Renderer(mtkView: v)
        r.uiParams = params
        v.delegate = r
        context.coordinator.renderer = r
        return v
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.setPaused(paused)  // mark pause/resume + retime tweens
        view.isPaused = paused                           // freeze/unfreeze draw loop (last frame stays)
        context.coordinator.renderer?.uiParams = params  // apply latest params (may start tweens)
    }



    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var renderer: Renderer? }
}
