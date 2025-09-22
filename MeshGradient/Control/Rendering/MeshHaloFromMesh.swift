//
//  MeshHaloFromMesh.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/22/25.
//


// MeshHaloFromMesh.swift

import SwiftUI

/// Uses the mesh itself to create a halo that extends beyond the ring.
/// The mesh is scaled to reach the target end radius and is masked with a radial ramp
/// that stays fully opaque until `startRadius`, then fades to 0 by `endRadius`.
struct MeshHaloFromMesh: View {
    let colors: [Color]
    var animate: Bool = true

    /// Additive deltas (points) relative to the circle rim (side * 0.5)
    /// startDelta < 0 means begin inside the rim; > 0 means outside.
    var startDelta: CGFloat = -4
    var endDelta: CGFloat = 20

    /// Visual tuning
    var softness: CGFloat = 20
    var opacity: Double = 0.9

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let rim = side * 0.5
            let startRadius = max(0, rim + startDelta)
            let endRadius   = max(startRadius + 1, rim + endDelta)

            // Scale factor so the mesh reaches the end radius.
            let scale = max(endRadius / max(1, rim), 1)

            // Extra pixels beyond the original square we need to cover the scaled mesh + blur.
            // rim*(scale-1) is the extra radius added by scaling; add softness*2 for blur spread.
            let bleed = max(0, endRadius - rim) + softness * 2
            let haloSize = side + 2 * bleed

            // Keep the base layout square,
            // and overlay a larger drawing region for the halo so it doesn't get rectangularly clipped.
            Color.clear
                .frame(width: side, height: side)
                .overlay(alignment: .center) {
                    // The halo rendering region is larger than the container by `bleed` on all sides.
                    ZStack {
                        // Draw the scaled mesh centered within this larger region.
                        MeshColorCircle(colors: colors, animate: animate)
                            .frame(width: side, height: side)
                            .scaleEffect(scale, anchor: .center)
                            .mask(
                                // Fully opaque until `startRadius`, then fade to 0 by `endRadius`.
                                RadialGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .white, location: 0.0),
                                        .init(color: .white, location: startRadius / max(1, endRadius)),
                                        .init(color: .white.opacity(0), location: 1.0)
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: endRadius
                                )
                                // Make the mask view itself larger than the base rect to avoid rectangular clipping.
                                .frame(width: haloSize, height: haloSize)
                            )
                            .blur(radius: softness)
                            .opacity(opacity)
                            .compositingGroup() // helps avoid intermediate clipping in some effect chains
                            .allowsHitTesting(false)
                    }
                    .frame(width: haloSize, height: haloSize)
                }
        }
        .allowsHitTesting(false)
        .aspectRatio(1, contentMode: .fit)
    }
}
