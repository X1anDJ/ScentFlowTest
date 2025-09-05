import SwiftUI

/// A circular "container" with a liquid-glass style rim that holds the mesh gradient.
struct GradientContainerCircle: View {
    let colors: [Color]
    private let rimWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Rim (liquid-glass styled ring)
            GlassRing(width: rimWidth)
                .accessibilityHidden(true)
            
            // Inner gradient disk
            MeshColorCircle(colors: colors)
                .padding(rimWidth) // inset inside the rim
        }
    }
}

/// Liquid-glass styled circular ring.
/// Uses materials + highlights so it works on current SDKs (no .glassEffect required).
private struct GlassRing: View {
    let width: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let shape = Circle()
            
            ZStack {
                // Base translucent ring
                shape
                    .strokeBorder(.ultraThinMaterial, lineWidth: width)
                    .overlay(
                        // Outer soft rim highlight
                        shape
                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                            .blur(radius: 0.6)
                            .blendMode(.overlay)
                    )
                    .overlay(
                        // Inner soft rim shadow
                        shape
                            .inset(by: width - 1)
                            .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                            .blur(radius: 0.6)
                    )
                    .overlay(
                        // Directional sheen across the ring
                        shape
                            .strokeBorder(LinearGradient(
                                colors: [
                                    .white.opacity(0.35),
                                    .white.opacity(0.05),
                                    .white.opacity(0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 0.9)
                            .blendMode(.overlay)
                            .opacity(0.8)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
