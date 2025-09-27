//
//  AnimationConfig.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/27/25.
//


import Foundation

/// Single source of truth for scale behavior.
enum AnimationConfig {
    static let startScale: Float = 0.24     // when there is 1 scent
    static let stepOfScale: Float = 0.1    // +/- per scent added/removed
    static let minScale:   Float = 0.2     // absolute floor
    static let maxScale:   Float = 1.2     // absolute ceiling

    /// Target scale for the given number of active scents.
    /// For 0 scents we clamp to the minimum (0.2).
    static func targetScale(forActiveScents n: Int) -> Float {
        guard n > 0 else { return minScale }
        let raw = startScale + Float(n - 1) * stepOfScale
        return clamp(raw)
    }

    /// Defensive clamp (use anywhere we accept external values).
    static func clamp(_ v: Float) -> Float {
        max(minScale, min(maxScale, v))
    }
}
