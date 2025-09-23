import SwiftUI
import UIKit

struct GradientContainerCircle: View {
    let colors: [Color]
    let fadingDuration: TimeInterval = 0.8
    var animate: Bool = true
    var isTemplate: Bool = false
    var meshOpacity: Double = 1.0
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Pull themed tokens from AppConfig
        let tokens = AppConfig.gradientCircleTokens(for: colorScheme)

        // Scale alpha differently per theme
        let displayColors = scaleAlphas(colors, tokens.colorUpperBound, by: tokens.colorAlphaScale)

        // Pick themed shadow based on current scheme
        let baseShadow = (colorScheme == .dark ? Theme.Shadow.wheelDark : Theme.Shadow.wheelLight)

        return ZStack {
            // Mesh-based halo extending beyond the ring
            if !isTemplate {
                MeshHaloFromMesh(
                    colors: displayColors,
                    animate: animate,
                    startDelta: tokens.glowStartInset,
                    endDelta: tokens.glowRadiusAdded,
                    softness: tokens.glowSoftness,
                    opacity: tokens.glowOpacity
                )
                .opacity(meshOpacity)
                // Fade timing for halo (decoupled from the spring)
                .animation(.easeInOut(duration: fadingDuration), value: meshOpacity)
            }

            // Fill to block halo from bleeding inward
            Circle()
                .fill(.background)
                .opacity(animate ? 0.8 : 0.4)
                .shadow(
                    color: baseShadow.opacity(animate ? 0.3 : 1.0),
                    radius: animate ? 15 : 30, x: 0, y: 0
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.4), value: animate)
            
//            GeometryReader { geo in
//                let r = min(geo.size.width, geo.size.height) / 2
//                Circle()
//                    .fill(Theme.CircleFill.gradient(for: colorScheme, radius: r * 3))
//                    .opacity(animate ? 0.0 : 1.0)
//                    .animation(.spring(response: 0.85, dampingFraction: 0.4), value: animate)
//            }
//            .aspectRatio(1, contentMode: .fit)

            
            Circle()
                .inset(by: tokens.rimWidth)
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            // Strongest in the center …
                            .init(
                                color: (colorScheme == .dark
                                        ? Theme.CircleFill.innerDark
                                        : Theme.CircleFill.innerLight),
                                location: 0.0
                            ),
                            // … then fade out before the edge (tune 0.75–0.9 as you like)
                            .init(
                                color: (colorScheme == .dark
                                        ? Theme.CircleFill.outerDark
                                        : Theme.CircleFill.outerLight),
                                location: 0.85
                            )
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: .infinity // let SwiftUI size it to the shape’s bounds
                    )
                )
                .opacity(animate ? 0.0 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.4), value: animate)
            
            // Glass ring (always visible)
            GlassRing(width: tokens.rimWidth)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            

            // Main mesh content inside the ring
            MeshColorCircle(colors: displayColors, animate: animate)
                .padding(tokens.rimWidth)
                .opacity(meshOpacity)
                // Fade timing for mesh (decoupled from the spring)
                .animation(.easeInOut(duration: fadingDuration), value: meshOpacity)
        }
        .aspectRatio(1, contentMode: .fit)
        // Power-driven raise/drop ONLY
        .scaleEffect(animate ? 1.0 : 0.95)
        .animation(.spring(response: 0.6, dampingFraction: 0.4), value: animate) // scoped to scale
    }


    /// Multiplies each color's alpha by `factor`, clamped to [0, 1].
    private func scaleAlphas(_ colors: [Color], _ upperBound: Double, by factor: Double) -> [Color] {
        colors.map { c in
            let ui = UIColor(c)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = upperBound
            
            if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
                let na = min(upperBound, max(0.0, Double(a) * factor))
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
