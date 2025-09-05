import SwiftUI
import Combine

final class GradientWheelViewModel: ObservableObject {
    // MARK: - Device (parent controls)
    @Published var isPowerOn: Bool = true
    @Published var fanSpeed: Double = 0.5   // reserved for later use

    func togglePower() { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { isPowerOn.toggle() } }
    func setFanSpeed(_ v: Double) { fanSpeed = max(0, min(1, v)) }

    // MARK: - Scents (existing)
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

    // selected names (max 6), per-scent intensity, and focus
    @Published var included: Set<String> = []
    @Published var opacities: [String: Double] = [:]
    @Published var focusedName: String?

    var canSelectMore: Bool { included.count < 6 }

    // MARK: - Toggle & intensity
    func toggle(_ name: String) {
        if included.contains(name) {
            if focusedName == name {
                included.remove(name)
                opacities[name] = nil
                // choose a new focus (next in canonical order) if available
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
            // NEW: default intensity to 50% of global cap when a scent is added
            opacities[name] = AppConfig.maxIntensity * 0.5
        }
    }

    func setOpacity(_ value: Double, for name: String) {
        // clamp to global max
        let clamped = max(0.0, min(AppConfig.maxIntensity, value))
        opacities[name] = clamped
    }

    // MARK: - Templates
    func applyTemplate(included newIncluded: Set<String>, opacities newOpacities: [String: Double]) {
        let limited = Array(newIncluded)
            .filter { colorDict[$0] != nil }
            .sorted { canonicalOrder.firstIndex(of: $0)! < canonicalOrder.firstIndex(of: $1)! }
            .prefix(6)

        included = Set(limited)
        focusedName = limited.first

        var out: [String: Double] = [:]
        for name in limited {
            let raw = newOpacities[name] ?? 0
            out[name] = max(0.0, min(AppConfig.maxIntensity, raw))
        }
        opacities = out
    }

    // MARK: - Renderer palette
    var selectedColorsWeighted: [Color] {
        let maxI = max(0.0001, AppConfig.maxIntensity)
        let names = canonicalOrder.filter { included.contains($0) }
        var stops: [Color] = names.compactMap { n in
            guard let base = colorDict[n] else { return nil }
            let a = min(AppConfig.maxIntensity, max(0, opacities[n] ?? 0))
            return a < 0.01 ? nil : base.opacity(a / maxI)
        }

        // Ensure visually rich mesh with at least 3 stops
        if stops.count == 1 {
            stops.append(contentsOf: [stops[0], .white.opacity(0.001)])
        } else if stops.count == 2 {
            stops.append(stops[0])
        }
        return stops
    }
}
