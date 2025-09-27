import SwiftUI

public struct RGBAColor: Codable, Hashable {
    public var r, g, b, a: Double
    public init(_ c: Color) {
        #if canImport(UIKit)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 1
        UIColor(c).getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        self.r = .init(rr); self.g = .init(gg); self.b = .init(bb); self.a = .init(aa)
        #else
        self.r = 1; self.g = 1; self.b = 1; self.a = 1
        #endif
    }
    public var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
}

public struct ScentPod: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var color: RGBAColor
    public var remainTime: TimeInterval  // seconds

    public init(id: UUID = .init(), name: String, color: Color, remainTime: TimeInterval) {
        self.id = id
        self.name = name
        self.color = RGBAColor(color)
        self.remainTime = remainTime
    }
}
