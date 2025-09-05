import SwiftUI
import Combine

final class GradientWheelViewModel: ObservableObject {
    // 7 canonical colors (name -> Color)
    @Published var colorDict: [String: Color] = [
        "Red": .red,
        "Orange": .orange,
        "Yellow": .yellow,
        "Green": .green,
        "Cyan": .cyan,
        "Blue": .blue,
        "Violet": .purple
    ]

    let canonicalOrder = ["Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Violet"]

    // Added colors (0–6)
    @Published var included: Set<String> = []

    // Per-color intensity (0…1). Default now honors the global cap.
    @Published var opacities: [String: Double] = [
        "Red": AppConfig.maxIntensity,
        "Orange": AppConfig.maxIntensity,
        "Yellow": AppConfig.maxIntensity,
        "Green": AppConfig.maxIntensity,
        "Cyan": AppConfig.maxIntensity,
        "Blue": AppConfig.maxIntensity,
        "Violet": AppConfig.maxIntensity
    ]

    // Which color the slider is currently editing
    @Published var focusedName: String? = nil

    var canSelectMore: Bool { included.count < 6 }

    /// Toggle logic:
    /// - If tapping an INCLUDED hue that is NOT focused -> just focus it (do NOT remove).
    /// - If tapping an INCLUDED hue that IS focused -> remove it, then focus the next available (if any).
    /// - If tapping a NOT-INCLUDED hue -> add it (respecting the cap) and focus it.
    func toggle(_ name: String) {
        if included.contains(name) {
            if focusedName == name {
                included.remove(name)
                if let next = canonicalOrder.first(where: { included.contains($0) }) {
                    focusedName = next
                } else {
                    focusedName = nil
                }
            } else {
                focusedName = name
            }
        } else {
            guard canSelectMore else { return }
            included.insert(name)
            focusedName = name
        }
    }

    /// Set intensity; clamp to the global max.
    func setOpacity(_ value: Double, for name: String) {
        opacities[name] = min(AppConfig.maxIntensity, max(0, value))
    }

    /// Apply a template to the current selection (clamps to global max).
    /// - Trims to canonical order and caps at 6 colors.
    func applyTemplate(included newIncluded: Set<String>, opacities newOpacities: [String: Double]) {
        let ordered = canonicalOrder.filter { newIncluded.contains($0) }
        let capped = Array(ordered.prefix(6))
        included = Set(capped)
        for name in capped {
            let raw = newOpacities[name] ?? AppConfig.maxIntensity
            opacities[name] = min(AppConfig.maxIntensity, max(0, raw))
        }
        focusedName = capped.first
    }

    /// Colors to feed the mesh.
    /// - Uses clamped intensity = min(opacity, AppConfig.maxIntensity)
    /// - Filters ~transparent entries.
    /// - Ensures at least 3 stops by synthesizing duplicates:
    ///   1 color a -> [a, a/2, a/4]; 2 colors -> duplicate the first at a/2.
    var selectedColorsWeighted: [Color] {
        let names = canonicalOrder.filter { included.contains($0) }

        // Capture base + clamped alpha so the cap applies even before any slider move.
        let entries: [(base: Color, alpha: Double)] = names.compactMap { name in
            guard let base = colorDict[name] else { return nil }
            let raw = opacities[name] ?? AppConfig.maxIntensity
            let a = min(AppConfig.maxIntensity, max(0, raw))
            guard a > 0.01 else { return nil }
            return (base, a)
        }

        switch entries.count {
        case 0:
            return []
        case 1:
            let (base, a) = entries[0]
            return [
                base.withAlpha(a),
                base.withAlpha(a / 2),
                base.withAlpha(a / 4)
            ]
        case 2:
            var out = entries.map { $0.base.withAlpha($0.alpha) }
            let (base, a) = entries[0]
            out.append(base.withAlpha(a / 2))
            return out
        default:
            return entries.map { $0.base.withAlpha($0.alpha) }
        }
    }
}

// MARK: - Color alpha utility
#if canImport(UIKit)
import UIKit
private extension Color {
    func withAlpha(_ a: Double) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &oldA) {
            return Color(.sRGB,
                         red: Double(r),
                         green: Double(g),
                         blue: Double(b),
                         opacity: a)
        }
        return self.opacity(a)
    }
}
#elseif canImport(AppKit)
import AppKit
private extension Color {
    func withAlpha(_ a: Double) -> Color {
        let ns = NSColor(self)
        guard let c = ns.usingColorSpace(.sRGB) else { return self }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &oldA)
        return Color(.sRGB,
                     red: Double(r),
                     green: Double(g),
                     blue: Double(b),
                     opacity: a)
    }
}
#endif
