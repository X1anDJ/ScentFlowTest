//
//  GlassBackground.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/9/25.
//


import SwiftUI

/// A tiny helper that uses the new Liquid Glass on iOS 26+
/// and gracefully falls back to `.ultraThinMaterial` on older iOS.
struct GlassBackground<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Liquid Glass on iOS 26+
            content
                .glassEffect(.regular, in: shape)
        } else {
            // Fallback for older iOS: material in the same shape
            content
                .background(.ultraThinMaterial, in: shape)
        }
    }
}

extension View {
    /// Apply a glass-like background automatically adapting to iOS 26+.
    func adaptiveGlassBackground<S: InsettableShape>(_ shape: S) -> some View {
        modifier(GlassBackground(shape: shape))
    }
}
