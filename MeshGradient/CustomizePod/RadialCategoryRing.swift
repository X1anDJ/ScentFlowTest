// RadialCategoryRing.swift
import SwiftUI

/// Evenly distributes category swatches around a circle (44×44),
/// and animates them fanning out clockwise along the circumference from 12 o'clock.
struct RadialCategoryRing: View {
    let items: [Category]
    let selectedSet: Set<String>
    let onTap: (Category) -> Void

    // Layout
    private let ringPadding: CGFloat = 16
    private let labelSpacing: CGFloat = 6
    private let startAngle: Double = -90       // 12 o'clock in degrees
    private let swatchSize: CGFloat = 44

    // Animation progress (0 -> all overlap at startAngle, 1 -> final layout)
    @State private var progress: Double = 0

    var body: some View {
        GeometryReader { geo in
            let minSide = min(geo.size.width, geo.size.height)
            let radius = max(0, (minSide / 2) - ringPadding - (swatchSize / 2))
            let step = 360.0 / Double(max(items.count, 1))
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                ForEach(Array(items.enumerated()), id: \.offset) { index, cat in
                    let countInCat = cat.optionsEN.reduce(into: 0) { if selectedSet.contains($1) { $0 += 1 } }
                    let endAngle = startAngle + Double(index) * step

                    VStack(spacing: labelSpacing) {
                        CategorySwatchButton(
                            tint: cat.color,
                            countSelectedInCategory: countInCat,
                            action: { onTap(cat) }
                        )
                        .frame(width: swatchSize, height: swatchSize)

                        Text(countInCat > 0 ? "\(cat.label) x \(countInCat)" : cat.label)
                            .font(.caption)
                            .foregroundStyle(countInCat > 0 ? .primary : .secondary)
                            .frame(maxWidth: 80)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    // <<< Animate ALONG the arc by animating the angle, not the .position
                    .modifier(ArcAlongCircle(
                        center: center,
                        radius: radius,
                        startAngleDegrees: startAngle,
                        endAngleDegrees: endAngle,
                        t: progress
                    ))
                }
            }
            .onAppear {
                // reset then animate to final layout along the ring
                progress = 0
                withAnimation(.easeOut(duration: 0.5)) {
                    progress = 1
                }
            }
        }
        .aspectRatio(1, contentMode: .fit) // keep it square
    }
}

/// Animates a view's position along a circular arc by interpolating the angle.
/// - Parameters:
///   - t: 0...1 progress; SwiftUI animates this via `animatableData`.
private struct ArcAlongCircle: AnimatableModifier {
    var center: CGPoint
    var radius: CGFloat
    var startAngleDegrees: Double
    var endAngleDegrees: Double
    var t: Double

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    func body(content: Content) -> some View {
        let angleDeg = startAngleDegrees + (endAngleDegrees - startAngleDegrees) * t
        let angleRad = angleDeg * .pi / 180
        let x = center.x + cos(angleRad) * radius
        let y = center.y + sin(angleRad) * radius
        return content.position(x: x, y: y)
    }
}


// If you don't already have this in a separate file:
struct CategorySwatchButton: View {
    var tint: Color
    var countSelectedInCategory: Int
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(tint.opacity(countSelectedInCategory > 0 ? 1.0 : 0.5))
                .modifier(GlassIfAvailable())
                .frame(width: 44, height: 44)
                .shadow(
                    color: countSelectedInCategory > 0 ? tint.opacity(0.8) : .clear,
                    radius: countSelectedInCategory > 0 ? 10 : 0
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(Text(countSelectedInCategory > 0 ? "Selected category" : "Category"))
    }
}
