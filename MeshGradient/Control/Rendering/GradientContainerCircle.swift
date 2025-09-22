import SwiftUI
import UIKit

struct GradientContainerCircle: View {
    let colors: [Color]
    var animate: Bool = true
    var isTemplate: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Pull themed tokens from AppConfig
        let tokens = AppConfig.gradientCircleTokens(for: colorScheme)

        // Scale alpha differently per theme
        let displayColors = scaleAlphas(colors, by: tokens.colorAlphaScale)

        return ZStack {
            // Mesh-based halo extending beyond the ring, with enlarged mask to avoid rectangular clip.
            if !isTemplate {
                MeshHaloFromMesh(
                    colors: displayColors,
                    animate: animate,
                    startDelta: tokens.glowStartInset,
                    endDelta: tokens.glowRadiusAdded,
                    softness: tokens.glowSoftness,
                    opacity: tokens.glowOpacity
                )
            }


            Circle()
                .fill(.background)

            // Glass ring
            GlassRing(width: tokens.rimWidth)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            // Main mesh content inside the ring
            MeshColorCircle(colors: displayColors, animate: animate)
                .padding(tokens.rimWidth)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Multiplies each color's alpha by `factor`, clamped to [0, 1].
    private func scaleAlphas(_ colors: [Color], by factor: Double) -> [Color] {
        colors.map { c in
            let ui = UIColor(c)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0.8
            
            print("49 line")
            if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
                let na = min(0.8, max(0.0, Double(a) * factor))
                return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: na)
            } else {
                return c
            }
            
            
        }
        
    }
}

private struct GlassRing: View {
    let width: CGFloat

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let shape = Circle()

            shape
                .strokeBorder(.ultraThinMaterial, lineWidth: width)
                .overlay(
                    shape.strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                )
                .overlay(
                    shape
                        .inset(by: width - 1)
                        .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                        .blur(radius: 0.6)
                )
                .overlay(
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.58),
                                    .white.opacity(0.06),
                                    .white.opacity(0.32)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                        .opacity(0.9)
                )
                .compositingGroup()
                .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .transaction { $0.animation = nil }
    }
}
