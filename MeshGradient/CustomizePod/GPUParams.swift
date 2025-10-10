//
//  GPUParams.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//


// GPUParams.swift
import simd

/// Must match `struct Params` in GradientShader.metal exactly (order & types).
/// Used as the constant buffer layout for the fragment shader.
struct GPUParams {
    // Scalars
    var time: Float = 0
    var speed: Float = 1
    var scale: Float = 1
    var warp: Float = 0
    var edge: Float = 0
    var separation: Float = 0
    var contrast: Float = 1

    // Aspect (w/h, 1)
    var aspect: SIMD2<Float> = .init(1, 1)

    // Colors (RGBA)
    var color1: SIMD4<Float> = .init(0, 0, 0, 1)
    var color2: SIMD4<Float> = .init(0, 0, 0, 1)
    var color3: SIMD4<Float> = .init(0, 0, 0, 1)
    var color4: SIMD4<Float> = .init(0, 0, 0, 1)
    var color5: SIMD4<Float> = .init(0, 0, 0, 1)
    var color6: SIMD4<Float> = .init(0, 0, 0, 1)

    // Masks
    var mask1: Float = 0
    var mask2: Float = 0
    var mask3: Float = 0
    var mask4: Float = 0
    var mask5: Float = 0
    var mask6: Float = 0

    // Intensities
    var intensity1: Float = 1
    var intensity2: Float = 1
    var intensity3: Float = 1
    var intensity4: Float = 1
    var intensity5: Float = 1
    var intensity6: Float = 1
}
