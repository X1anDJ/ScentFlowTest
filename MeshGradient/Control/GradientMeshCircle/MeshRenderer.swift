import SwiftUI

struct RendererConfig {
    var ensureMinStops: Bool = true
}

/// A renderer that produces a palette given the current wheel inputs.
/// (We no longer depend on Mix/Scent.)
protocol MeshRenderer {
    func palette(
        orderedPodIDs: [UUID],
        colorsByPodID: [UUID: Color],
        included: Set<UUID>,
        opacities: [UUID: Double],
        maxIntensity: Double
    ) -> [Color]
}

struct DefaultMeshRenderer: MeshRenderer {
    var config: RendererConfig = .init()

    func palette(
        orderedPodIDs: [UUID],
        colorsByPodID: [UUID: Color],
        included: Set<UUID>,
        opacities: [UUID: Double],
        maxIntensity: Double
    ) -> [Color] {
        let maxI = max(0.0001, maxIntensity)

        let entries: [(Color, Double)] = orderedPodIDs
            .filter { included.contains($0) }
            .compactMap { id in
                guard let base = colorsByPodID[id] else { return nil }
                let raw = opacities[id] ?? 0
                let a = min(maxIntensity, max(0, raw))
                return a > 0.01 ? (base, a) : nil
            }

        func withAlpha(_ c: Color, _ a: Double) -> Color {
            #if canImport(UIKit)
            let ui = UIColor(c)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
            if ui.getRed(&r, green: &g, blue:&b, alpha:&oldA) {
                return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: a / maxI)
            }
            #endif
            return c.opacity(a / maxI)
        }

        var stops = entries.map { withAlpha($0.0, $0.1) }
        guard config.ensureMinStops else { return stops }

        switch stops.count {
        case 0: return []
        case 1: return [stops[0].opacity(0.5), stops[0], stops[0].opacity(0.7)]
        case 2: return [stops[0], stops[1], stops[0]]
        default: return stops
        }
    }
}
