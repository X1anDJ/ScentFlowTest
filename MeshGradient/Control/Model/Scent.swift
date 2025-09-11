//
//  Scent.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//


import SwiftUI

/// A single scent definition in the catalog.
struct Scent: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    // NOTE: We do not encode `Color`; only the model. Color comes from theme/coding elsewhere if needed.
    var colorHex: String
    var defaultIntensity: Double

    init(id: UUID = UUID(), name: String, color: Color, defaultIntensity: Double) {
        self.id = id
        self.name = name
        self.colorHex = color.toHexSRGB() ?? "#FFFFFF"
        self.defaultIntensity = defaultIntensity
    }

    // Runtime Color
    var color: Color { Color.fromHex(colorHex) ?? .gray }
}

/// Helpers to convert Color <-> hex in sRGB (best-effort).
extension Color {
    func toHexSRGB() -> String? {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
        #elseif canImport(AppKit)
        let ns = NSColor(self)
        guard let s = ns.usingColorSpace(.sRGB) else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        s.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
        #else
        return nil
        #endif
    }

    static func fromHex(_ hex: String) -> Color? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = Int(h, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF)/255.0
        let g = Double((v >> 8) & 0xFF)/255.0
        let b = Double(v & 0xFF)/255.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
