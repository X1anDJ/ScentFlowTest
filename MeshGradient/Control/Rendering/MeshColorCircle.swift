import SwiftUI

/// 0 colors -> nothing
/// >=1      -> Mesh (if 1 color, caller should pass [color, .white] to enrich)
struct MeshColorCircle: View {
    let colors: [Color]
    /// When `false`, the mesh is rendered statically (no animation).
    var animate: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var paused: Bool { !animate || reduceMotion || scenePhase != .active }

    var body: some View {
        ZStack {
            if colors.isEmpty {
                Color.clear
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { ctx in
                    // Compute midX as a single expression (no assignments-as-statements).
                    let midX: CGFloat = {
                        if paused { return 0.9 }
                        let t = ctx.date.timeIntervalSinceReferenceDate
                        let phase = sin((t / 10.0) * 2.0 * .pi)     // -1…1
                        return 0.5 + 0.4 * CGFloat(phase)          // 0.1…0.9
                    }()

                    MeshDisk(colors: colors, midX: midX)
                }
            }
        }
    }
}

/// Circle-clipped mesh using native MeshGradient (iOS 18+/macOS 15+) or Canvas fallback.
private struct MeshDisk: View {
    let colors: [Color]
    var midX: CGFloat   // 0…1

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let size = CGSize(width: side, height: side)

            ZStack {
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
                    Circle()
                        .fill(
                            MeshGradient(
                                width: 3, height: 3,
                                points: animatedPoints(midX: Float(midX)),
                                colors: meshColors(from: colors),
                                smoothsColors: true,
                                colorSpace: .perceptual
                            )
                        )
                } else {
                    CanvasMeshFallback(colors: colors, midX: midX)
                        .clipShape(Circle())
                }
            }
            .frame(width: size.width, height: size.height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func animatedPoints(midX: Float) -> [SIMD2<Float>] {
        [
            .init(0, 0),   .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(midX, 0.5), .init(1, 0.5),
            .init(0, 1),   .init(0.5, 1), .init(1, 1)
        ]
    }

    private func meshColors(from selected: [Color]) -> [Color] {
        var out: [Color] = []
        out.reserveCapacity(9)
        for i in 0..<9 { out.append(selected[i % selected.count]) }
        return out
    }
}

/// Additive-blend Canvas fallback for older OS versions.
private struct CanvasMeshFallback: View {
    let colors: [Color]
    var midX: CGFloat
    private let lobeRadiusScale: CGFloat = 0.55

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let rect = CGRect(
                x: (geo.size.width - side) / 2,
                y: (geo.size.height - side) / 2,
                width: side, height: side
            )

            Canvas(rendersAsynchronously: true) { context, _ in
                context.clip(to: Path(ellipseIn: rect))
                context.blendMode = .plusLighter

                let pts = fallbackPoints(in: rect, midX: midX)
                let r = side * lobeRadiusScale
                let meshCols = (0..<9).map { colors[$0 % colors.count] }

                for (idx, color) in meshCols.enumerated() {
                    let p = pts[idx]
                    let lobeRect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
                    let gradient = Gradient(stops: [
                        .init(color: color.opacity(1.0), location: 0.0),
                        .init(color: color.opacity(0.0), location: 1.0)
                    ])
                    context.fill(
                        Path(ellipseIn: lobeRect),
                        with: .radialGradient(gradient, center: p, startRadius: 0, endRadius: r)
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func fallbackPoints(in rect: CGRect, midX: CGFloat) -> [CGPoint] {
        let raw: [SIMD2<Float>] = [
            .init(0, 0),   .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(Float(midX), 0.5), .init(1, 0.5),
            .init(0, 1),   .init(0.5, 1), .init(1, 1)
        ]
        return raw.map { v in
            CGPoint(x: rect.minX + CGFloat(v.x) * rect.width,
                    y: rect.minY + CGFloat(v.y) * rect.height)
        }
    }
}
