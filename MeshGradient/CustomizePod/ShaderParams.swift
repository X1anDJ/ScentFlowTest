import SwiftUI
import simd

/// Swift-side params you edit via UI (targets).
/// Renderer owns the animated "current" values and eases toward these.
struct ShaderParams: Equatable {
    // Knobs (targets)
    var speed: Float      = 1.8
    var scale: Float      = 0.2   // target scale; renderer eases toward this
    var warp:  Float      = 2.0
    var edge:  Float      = 0.5
    var separation: Float = 6.0
    var contrast:   Float = 1.4

    // View aspect (w/h, 1)
    var aspect: SIMD2<Float> = .init(1, 1)

    // Up to 6 channels — colors
    var color1: SIMD4<Float> = .init(0,0,0,1)
    var color2: SIMD4<Float> = .init(0,0,0,1)
    var color3: SIMD4<Float> = .init(0,0,0,1)
    var color4: SIMD4<Float> = .init(0,0,0,1)
    var color5: SIMD4<Float> = .init(0,0,0,1)
    var color6: SIMD4<Float> = .init(0,0,0,1)

    // Masks derived from activeColors (1 for indices [0..<activeColors), else 0)
    var mask1: Float = 0
    var mask2: Float = 0
    var mask3: Float = 0
    var mask4: Float = 0
    var mask5: Float = 0
    var mask6: Float = 0

    // Per-channel intensity (targets)
    var intensity1: Float = 1
    var intensity2: Float = 1
    var intensity3: Float = 1
    var intensity4: Float = 1
    var intensity5: Float = 1
    var intensity6: Float = 1

    /// Optional add/remove pulses for clarity (−1 means “no pulse”).
    /// Renderer will prefer these over inferring from mask edges.
    var addedIndex:   Int32 = -1
    var removedIndex: Int32 = -1
}

// MARK: - Convenience builders

extension ShaderParams {
    mutating func setColors(_ c: [SIMD4<Float>]) {
        let arr = (c + Array(repeating: SIMD4<Float>(0,0,0,1), count: 6)).prefix(6)
        self.color1 = arr[0]; self.color2 = arr[1]; self.color3 = arr[2]
        self.color4 = arr[3]; self.color5 = arr[4]; self.color6 = arr[5]
    }

    mutating func setMasks(activeCount n: Int) {
        let bits: [Float] = (0..<6).map { $0 < n ? 1 : 0 }
        self.mask1 = bits[0]; self.mask2 = bits[1]; self.mask3 = bits[2]
        self.mask4 = bits[3]; self.mask5 = bits[4]; self.mask6 = bits[5]
    }

    mutating func setIntensities(_ v: [Float]) {
        let arr = (v + Array(repeating: Float(1), count: 6)).prefix(6)
        self.intensity1 = arr[0]; self.intensity2 = arr[1]; self.intensity3 = arr[2]
        self.intensity4 = arr[3]; self.intensity5 = arr[4]; self.intensity6 = arr[5]
    }
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
