import SwiftUI

public struct RGBAColor: Codable, Hashable {
    public var r, g, b, a: Double

    public init(_ c: Color) {
        #if canImport(UIKit)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 1
        UIColor(c).getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        self.r = .init(rr)
        self.g = .init(gg)
        self.b = .init(bb)
        self.a = .init(aa)
        #else
        self.r = 1
        self.g = 1
        self.b = 1
        self.a = 1
        #endif
    }

    public var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

public enum PodLiquidLevel: String, Codable, Hashable, CaseIterable {
    case normal
    case low
    case empty

    public var title: String {
        switch self {
        case .normal: return "Normal"
        case .low: return "Low"
        case .empty: return "Empty"
        }
    }

    public var tintColor: Color {
        switch self {
        case .normal: return .green
        case .low: return .orange
        case .empty: return .red
        }
    }
}

public struct ScentPod: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var color: RGBAColor
    public var level: PodLiquidLevel

    public init(
        id: UUID = .init(),
        name: String,
        color: Color,
        level: PodLiquidLevel
    ) {
        self.id = id
        self.name = name
        self.color = RGBAColor(color)
        self.level = level
    }
}
