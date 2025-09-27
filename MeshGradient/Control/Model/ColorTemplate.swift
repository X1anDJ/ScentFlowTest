//import SwiftUI
//
//// MARK: - ColorTemplateV2
///// Keep templates lightweight: reference pods by id.
///// (You asked for an array of scents; storing ids prevents duplication and eases updates.)
//public struct ColorTemplateV2: Identifiable, Codable, Hashable {
//    public let id: UUID
//    public var name: String
//    public var scentPodIDs: [UUID]   // order in this array = display order
//
//    public init(id: UUID = UUID(), name: String, scentPodIDs: [UUID]) {
//        self.id = id
//        self.name = name
//        self.scentPodIDs = scentPodIDs
//    }
//}
//
//// MARK: - Palette helper (mirrors VM behavior and global cap)
///// Build a preview palette so template cards match the main wheel look.
//func buildPalette(
//    canonicalOrder: [String],
//    colorDict: [String: Color],
//    included: Set<String>,
//    opacities: [String: Double]
//) -> [Color] {
//
//    // Collect (base color, effective alpha) for the included names in canonical order.
//    let entries: [(Color, Double)] = canonicalOrder
//        .filter { included.contains($0) }
//        .compactMap { name in
//            guard let base = colorDict[name] else { return nil }
//            let raw = opacities[name] ?? AppConfig.maxIntensity
//            let a = min(AppConfig.maxIntensity, max(0, raw)) // enforce global cap
//            return a > 0.01 ? (base, a) : nil
//        }
//
//    // Convert to Color with the right display alpha normalized to the global cap.
//    func withAlpha(_ c: Color, _ a: Double) -> Color {
//        let maxI = max(0.0001, AppConfig.maxIntensity)
//        return c.opacity(a / maxI)
//    }
//
//    // Ensure ≥3 stops for a richer mesh (same strategy as the wheel).
//    switch entries.count {
//    case 0:
//        return []
//    case 1:
//        let (base, a) = entries[0]
//        return [withAlpha(base, a), withAlpha(base, a / 2), withAlpha(base, a / 4)]
//    case 2:
//        var out = entries.map { withAlpha($0.0, $0.1) }
//        out.append(withAlpha(entries[0].0, entries[0].1 / 2))
//        return out
//    default:
//        return entries.map { withAlpha($0.0, $0.1) }
//    }
//}
