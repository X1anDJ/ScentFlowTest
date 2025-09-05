import SwiftUI

/// 0 colors -> GlassyCircle
/// >=1      -> Mesh (if 1 color, caller passes [color, .white])
struct MeshColorCircle: View {
    let colors: [Color]
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if colors.isEmpty {
                GlassyCircle()
            } else {
                MeshDisk(colors: colors, isAnimating: isAnimating)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                            isAnimating.toggle()
                        }
                    }
            }
        }
    }
}

/// Circle-clipped mesh using native MeshGradient (iOS 18+/macOS 15+) or Canvas fallback.
private struct MeshDisk: View {
    let colors: [Color]
    var isAnimating: Bool
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let rect = CGRect(x: (geo.size.width - side) / 2,
                              y: (geo.size.height - side) / 2,
                              width: side, height: side)
            ZStack {
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
                    Circle()
                        .fill(
                            MeshGradient(
                                width: 3, height: 3,
                                points: animatedPoints(isAnimating: isAnimating),
                                colors: meshColors(from: colors),
                                smoothsColors: true,
                                colorSpace: .perceptual
                            )
                        )
                } else {
                    CanvasMeshFallback(colors: colors, isAnimating: isAnimating)
                        .clipShape(Circle())
                }
            }
            .frame(width: rect.width, height: rect.height)
            .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func animatedPoints(isAnimating: Bool) -> [SIMD2<Float>] {
        [
            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
            SIMD2<Float>(0.0, 0.5), SIMD2<Float>(isAnimating ? 0.1 : 0.9, 0.5), SIMD2<Float>(1.0, 0.5),
            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
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
    var isAnimating: Bool
    private let lobeRadiusScale: CGFloat = 0.55
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let rect = CGRect(x: (geo.size.width - side) / 2,
                              y: (geo.size.height - side) / 2,
                              width: side, height: side)
            Canvas { context, _ in
                context.clip(to: Path(ellipseIn: rect))
                let pts = fallbackPoints(in: rect, isAnimating: isAnimating)
                let r = side * lobeRadiusScale
                context.blendMode = .plusLighter
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
    }
    
    private func fallbackPoints(in rect: CGRect, isAnimating: Bool) -> [CGPoint] {
        let raw: [SIMD2<Float>] = [
            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
            SIMD2<Float>(0.0, 0.5), SIMD2<Float>(isAnimating ? 0.1 : 0.9, 0.5), SIMD2<Float>(1.0, 0.5),
            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
        ]
        return raw.map { v in
            CGPoint(x: rect.minX + CGFloat(v.x) * rect.width,
                    y: rect.minY + CGFloat(v.y) * rect.height)
        }
    }
}
