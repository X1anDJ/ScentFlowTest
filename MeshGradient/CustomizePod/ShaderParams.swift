import SwiftUI
import simd

// MARK: - Swift-side params you edit via UI
struct ShaderParams: Equatable {
    var speed: Float      = 1.8
    var scale: Float      = 1.0   // start at 1.0 (target scale; renderer animates toward it)
    var warp:  Float      = 2.0
    var edge:  Float      = 0.5
    var separation: Float = 6.0
    var contrast:   Float = 1.4

    var color1: SIMD4<Float> = .init(0,0,0,1)
    var color2: SIMD4<Float> = .init(0,0,0,1)
    var color3: SIMD4<Float> = .init(0,0,0,1)
    var color4: SIMD4<Float> = .init(0,0,0,1)
    var color5: SIMD4<Float> = .init(0,0,0,1)
    var color6: SIMD4<Float> = .init(0,0,0,1)

    var mask1: Float = 0
    var mask2: Float = 0
    var mask3: Float = 0
    var mask4: Float = 0
    var mask5: Float = 0
    var mask6: Float = 0

    var intensity1: Float = 1
    var intensity2: Float = 1
    var intensity3: Float = 1
    var intensity4: Float = 1
    var intensity5: Float = 1
    var intensity6: Float = 1
    // Index of newly added scent (0...5); -1 means none; used only by Renderer for fade-in
    var addedIndex: Int32 = -1
}

// MARK: - GPU struct exactly matching MSL layout
// Keep field order + padding aligned with Metal's 'Params'
struct GPUParams {
    var time: Float = 0
    var speed: Float = 0
    var scale: Float = 0
    var warp:  Float = 0
    var edge:  Float = 0
    var separation: Float = 0
    var contrast:   Float = 1
    var _pad0: Float = 0            // padding so 'aspect' starts on 32B boundary
    var aspect: SIMD2<Float> = .init(1,1)

    var color1: SIMD4<Float> = .init(0,0,0,1)
    var color2: SIMD4<Float> = .init(0,0,0,1)
    var color3: SIMD4<Float> = .init(0,0,0,1)
    var color4: SIMD4<Float> = .init(0,0,0,1)
    var color5: SIMD4<Float> = .init(0,0,0,1)
    var color6: SIMD4<Float> = .init(0,0,0,1)

    var mask1: Float = 0
    var mask2: Float = 0
    var mask3: Float = 0
    var mask4: Float = 0
    var mask5: Float = 0
    var mask6: Float = 0

    var intensity1: Float = 1
    var intensity2: Float = 1
    var intensity3: Float = 1
    var intensity4: Float = 1
    var intensity5: Float = 1
    var intensity6: Float = 1
}

// MARK: - Color helper
extension Color {
    func toSIMD4() -> SIMD4<Float> {
        #if os(iOS)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))
        #else
        return SIMD4<Float>(0,0,0,1)
        #endif
    }
}
