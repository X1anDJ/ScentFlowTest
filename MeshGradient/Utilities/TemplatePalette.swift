//
//  TemplatePalette.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//

import SwiftUI

/// Builds a palette for previewing a template so the gallery card matches the wheel.
/// - Parameters:
///   - names: Canonical scent order (same array you pass to the wheel/controls)
///   - colorDict: Mapping name -> Color
///   - included: Selected scent names
///   - opacities: Effective per-scent intensity in 0...AppConfig.maxIntensity
/// - Returns: Colors to feed into GradientContainerCircle
func buildTemplatePalette(
    names: [String],
    colorDict: [String: Color],
    included: Set<String>,
    opacities: [String: Double]
) -> [Color] {

    // (Color, alpha) pairs for included items only, clamped by global cap
    let entries: [(Color, Double)] = names
        .filter { included.contains($0) }
        .compactMap { name in
            guard let base = colorDict[name] else { return nil }
            let raw = opacities[name] ?? AppConfig.maxIntensity
            let a = min(AppConfig.maxIntensity, max(0, raw))
            return a > 0.01 ? (base, a) : nil
        }

    // Convert to Color with explicit opacity in sRGB so previews are consistent.
    func withAlpha(_ c: Color, _ a: Double) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
        if ui.getRed(&r, green: &g, blue:&b, alpha:&oldA) {
            return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: a)
        }
        return c.opacity(a)
        #elseif canImport(AppKit)
        let ns = NSColor(c)
        guard let s = ns.usingColorSpace(.sRGB) else { return c.opacity(a) }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
        s.getRed(&r, green: &g, blue: &b, alpha: &oldA)
        return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: a)
        #else
        return c.opacity(a)
        #endif
    }

    // Ensure ≥3 stops for a richer mesh preview (mirrors your old behavior)
    switch entries.count {
    case 0:
        return []
    case 1:
        let (base, a) = entries[0]
        return [withAlpha(base, a), withAlpha(base, a/2), withAlpha(base, a/4)]
    case 2:
        var out = entries.map { withAlpha($0.0, $0.1) }
        out.append(withAlpha(entries[0].0, entries[0].1 / 2))
        return out
    default:
        return entries.map { withAlpha($0.0, $0.1) }
    }
}
