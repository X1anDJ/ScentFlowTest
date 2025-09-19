import SwiftUI
import UIKit


/// A circular container with a liquid-glass rim that holds the mesh gradient.
/// Optimized: reduced overdraw on the ring; animation handled inside MeshColorCircle.
struct GradientContainerCircle: View {
    let colors: [Color]
    /// When `false`, inner mesh is static (no animation). Default = true.
    var animate: Bool = true

    private let rimWidth: CGFloat = 8
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Appearance-only tweak: boost intensity in Dark Mode
        let displayColors = colorScheme == .dark
            ? scaleAlphas(colors, by: 1.2)   // multiply alpha by 1.2 (clamped)
            : scaleAlphas(colors, by: 0.85)

        return ZStack {
            GlassRing(width: rimWidth)
                .accessibilityHidden(true)
                .allowsHitTesting(false)

            // Inner gradient disk
            MeshColorCircle(colors: displayColors, animate: animate)
                .padding(rimWidth) // inset inside the rim
        }
        .aspectRatio(1, contentMode: .fit)
        
    }

    /// Multiplies each color's alpha by `factor`, clamped to [0, 1].
    private func scaleAlphas(_ colors: [Color], by factor: Double) -> [Color] {
        colors.map { c in
            let ui = UIColor(c)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
            if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
                let na = min(1.0, max(0.0, Double(a) * factor))
                return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: na)
            } else {
                return c // fallback (keep as-is)
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
                // Outer edge highlight
                .overlay(
                    shape.strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                )
                // Inner soft rim shadow
                .overlay(
                    shape
                        .inset(by: width - 1)
                        .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                        .blur(radius: 0.6)
                )
                // Single directional sheen
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
                // Subtle lift
                .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                // Collapse blending work to one pass
                .compositingGroup()
                .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .transaction { $0.animation = nil } // avoid implicit anims if parent animates
    }
}
