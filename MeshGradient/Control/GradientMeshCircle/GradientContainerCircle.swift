import SwiftUI
import UIKit

struct GradientContainerCircle: View {
    let colors: [Color]
    let fadingDuration: TimeInterval = 0.8
    var animate: Bool = true
    var isTemplate: Bool = false
    var meshOpacity: Double = 1.0
    
    // Power behavior mirrored from PowerButtonRow:
    var isOn: Bool = false
    var onToggle: () -> Void = { }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        // Pull themed tokens from AppConfig
        let tokens = AppConfig.gradientCircleTokens(for: colorScheme)
        
        // Scale alpha differently per theme
        let displayColors = scaleAlphas(colors, tokens.colorUpperBound, by: tokens.colorAlphaScale)
        
        // Pick themed shadow based on current scheme
        let baseShadow = (colorScheme == .dark ? Theme.Shadow.wheelDark : Theme.Shadow.wheelLight)
        
        return ZStack {
            ZStack {
                // Mesh-based halo extending beyond the ring
                if !isTemplate {
                    MeshHaloShadowFromMesh(
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
                    .fill(
                        .background
                        
                    )
                    .opacity(animate ? 0.8 : 0.4)
                    .shadow(
                        color: baseShadow.opacity(animate ? 0.3 : 1.0),
                        radius: animate ? 15 : 30, x: 0, y: 0
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.4), value: animate)
                
                
                Circle()
                    //.inset(by: tokens.rimWidth)
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
                    .animation(.easeInOut(duration: fadingDuration), value: animate)
//                    .animation(.spring(response: 0.6, dampingFraction: 0.4), value: animate)
                
                // Glass ring (always visible)
                GlassRing(width: tokens.rimWidth, isOn: animate)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .animation(.spring(response: 0.6, dampingFraction: 0.4), value: animate)
                
                // Main mesh content inside the ring
                MeshColorCircle(colors: displayColors, animate: animate)
                    //.padding(tokens.rimWidth)
                    .opacity(meshOpacity)
                // Fade timing for mesh (decoupled from the spring)
                    .animation(.easeInOut(duration: fadingDuration), value: meshOpacity)
            }
            .aspectRatio(1, contentMode: .fit)
            // Power-driven raise/drop ONLY
            .scaleEffect(animate ? 1.0 : 0.95)
            .animation(.spring(response: 0.4, dampingFraction: 0.4), value: animate) // scoped to scale
//
//            // Power Button Testing
//            if !isTemplate {
//                // Center power button overlay (60x60), icon-only.
//                Button(action: onToggle) {
//                    Image(systemName: "power")
//                        .font(.system(size: 26, weight: .semibold))
//                        .frame(width: 60, height: 60)
//                        .animation(nil, value: isOn)
//                }
//                                        .clipShape(Circle())
//                .transaction { txn in txn.animation = nil }
//                .buttonStyle(.glass)
//                .accessibilityLabel("Toggle power")
//                .accessibilityValue(isOn ? "On" : "Off")
//            }

        }
        
        
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
    var isOn: Bool
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let shape = Circle()
            
            shape
                .strokeBorder(
//                    Color.gray.opacity(0.4),
//                    lineWidth: width
                    
                    LinearGradient(
                        colors: [
                            isOn ? .white.opacity(0.15) : .clear ,
                            .black.opacity(0.1),
                            isOn ? .gray.opacity(0.1) : .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) ,
                    lineWidth: width
                )
                .overlay {
                    if isOn {
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.25),
                                        .gray.opacity(0.3),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .blendMode(.overlay)
                            .opacity(0.9)
                    } else {
                        shape
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    }
                }

                .overlay(
                    shape
                        .inset(by: width - 1)   // Inner line
                        .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                        .blur(radius: 0.6)
                )
                .compositingGroup()
                .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .transaction { $0.animation = nil }
    }
}


struct GradientContainerCircle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode, powered on
            GradientContainerCircle(
                colors: [.red, .orange, .yellow, .green, .blue, .purple],
                animate: true,
                isTemplate: false,
                meshOpacity: 1.0,
                isOn: true,
                onToggle: {}
            )
            .padding()
            .previewDisplayName("Light - On")
            .preferredColorScheme(.light)

            // Dark mode, powered off
            GradientContainerCircle(
                colors: [ ],
                animate: true,
                isTemplate: false,
                meshOpacity: 0.6,
                isOn: true,
                onToggle: {}
            )
            .padding()
            .previewDisplayName("Dark - Off")
            .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
