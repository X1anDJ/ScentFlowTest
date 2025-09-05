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
    
    // Per-color opacity (0…1). Defaults to 1.
    @Published var opacities: [String: Double] = [
        "Red": 1, "Orange": 1, "Yellow": 1, "Green": 1, "Cyan": 1, "Blue": 1, "Violet": 1
    ]
    
    // Which color the slider is currently editing
    @Published var focusedName: String? = nil
    
    var canSelectMore: Bool { included.count < 6 }
    
    func toggle(_ name: String) {
        if included.contains(name) {
            included.remove(name)
        } else {
            guard canSelectMore else { return }
            included.insert(name)
        }
        focusedName = name // focus the tapped color either way
    }
    
    func setOpacity(_ value: Double, for name: String) {
        opacities[name] = min(1, max(0, value))
    }
    
    /// Colors to feed the mesh.
    /// - Applies per-hue opacity and filters near-zero alphas.
    /// - Ensures the mesh has at least 3 stops by synthesizing duplicates:
    ///   1 color a -> [a, a/2, a/4]; 2 colors -> duplicate the first at a/2.
    var selectedColorsWeighted: [Color] {
        let names = canonicalOrder.filter { included.contains($0) }
        
        // Capture base + alpha so we can synthesize deterministically.
        let entries: [(base: Color, alpha: Double)] = names.compactMap { name in
            guard let base = colorDict[name] else { return nil }
            let a = opacities[name] ?? 1
            guard a > 0.01 else { return nil }
            return (base, a)
        }
        
        switch entries.count {
        case 0:
            return []
        case 1:
            let (base, a) = entries[0]
            // e.g. 0.8 -> [0.8, 0.4, 0.2]
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
                         opacity: a)   // SwiftUI Color uses `opacity:`
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
