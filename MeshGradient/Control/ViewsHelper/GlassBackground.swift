//
//  GlassBackground.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/9/25.
//

import SwiftUI

/// Glass/material background helper that prefers iOS 26 Liquid Glass,
/// and falls back to material on earlier systems.
struct AdaptiveGlassBackground<FallbackShape: Shape>: ViewModifier {
    let fallbackShape: FallbackShape
    let useConcentricOnIOS26: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            if useConcentricOnIOS26 {
                content.glassEffect(.regular, in: ConcentricRectangle())
            } else {
                content.glassEffect(.regular, in: fallbackShape)
            }
        } else {
            content.background(.ultraThinMaterial, in: fallbackShape)
        }
        #else
        content.background(.ultraThinMaterial, in: fallbackShape)
        #endif
    }
}

extension View {
    /// Apply a glassy background clipped to `shape`, using the best API available.
    ///
    /// - Parameters:
    ///   - shape: Fallback shape for pre-iOS 26 systems, or the explicit iOS 26 shape when
    ///            `useConcentricOnIOS26` is false.
    ///   - useConcentricOnIOS26: Uses `ConcentricRectangle()` on iOS 26+.
    func adaptiveGlassBackground<S: Shape>(
        _ shape: S,
        useConcentricOnIOS26: Bool = false
    ) -> some View {
        modifier(
            AdaptiveGlassBackground(
                fallbackShape: shape,
                useConcentricOnIOS26: useConcentricOnIOS26
            )
        )
    }
}
