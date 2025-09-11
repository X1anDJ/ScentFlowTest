//
//  MeshRenderer.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//

import SwiftUI

struct RendererConfig {
    var ensureMinStops: Bool = true
}

protocol MeshRenderer {
    func palette(for mix: Mix, catalog: [UUID: Scent], order: [UUID]) -> [Color]
}

struct DefaultMeshRenderer: MeshRenderer {
    var config: RendererConfig = .init()

    func palette(for mix: Mix, catalog: [UUID: Scent], order: [UUID]) -> [Color] {
        let maxI = max(0.0001, AppConfig.maxIntensity)

        let entries: [(Color, Double)] = order
            .filter { mix.selected.contains($0) }
            .compactMap { id in
                guard let scent = catalog[id] else { return nil }
                let raw = mix.intensity[id] ?? scent.defaultIntensity
                let a = min(AppConfig.maxIntensity, max(0, raw))
                return a > 0.01 ? (scent.color, a) : nil
            }

        func withAlpha(_ c: Color, _ a: Double) -> Color {
            #if canImport(UIKit)
            let ui = UIColor(c)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
            if ui.getRed(&r, green: &g, blue:&b, alpha:&oldA) {
                return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: a / maxI)
            }
            return c.opacity(a / maxI)
            #elseif canImport(AppKit)
            let ns = NSColor(c)
            guard let s = ns.usingColorSpace(.sRGB) else { return c.opacity(a / maxI) }
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
            s.getRed(&r, green: &g, blue: &b, alpha: &oldA)
            return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: a / maxI)
            #else
            return c.opacity(a / maxI)
            #endif
        }

        var stops = entries.map { withAlpha($0.0, $0.1) }
        guard config.ensureMinStops else { return stops }

        switch stops.count {
        case 0: return []
        case 1: return [stops[0], stops[0], .white.opacity(0.001)]
        case 2: return [stops[0], stops[1], stops[0]]
        default: return stops
        }
    }
}
