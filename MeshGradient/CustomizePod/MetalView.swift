import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    var params: ShaderParams

    func makeUIView(context: Context) -> MTKView {
        let v = MTKView()
        v.device = MTLCreateSystemDefaultDevice()
        v.clearColor = MTLClearColorMake(0, 0, 0, 0) // transparent so glass look works
        v.framebufferOnly = false
        v.enableSetNeedsDisplay = false
        v.isPaused = false
        v.preferredFramesPerSecond = 30

        let r = Renderer(mtkView: v)
        r.uiParams = params
        v.delegate = r
        context.coordinator.renderer = r
        return v
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.uiParams = params
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var renderer: Renderer? }
}
