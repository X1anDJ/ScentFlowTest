//
//  GlassBackground.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/9/25.
//

import SwiftUI

/// Glass/material background helper that prefers the newest iOS 26 API,
/// and gracefully falls back on earlier systems.
struct AdaptiveGlassBackground<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            // Your desired effect on iOS 26+
            content.glassEffect(.regular, in: shape)
        } else {
            // Earlier iOS: approximate with material
            content.background(.ultraThinMaterial, in: shape)
        }
        #else
        // Non-iOS platforms: material fallback
        content.background(.ultraThinMaterial, in: shape)
        #endif
    }
}

extension View {
    /// Apply a glassy background clipped to `shape`, using the best API available.
    func adaptiveGlassBackground<S: Shape>(_ shape: S) -> some View {
        modifier(AdaptiveGlassBackground(shape: shape))
    }
}
