//import SwiftUI
//import Combine
//
///// Handles scent catalog, selection, intensity, and focus.
//@MainActor
//final class MixDomain: ObservableObject {
//    @Published private(set) var catalog: [UUID: Scent]
//    @Published private(set) var order: [UUID]
//    @Published var mix: Mix
//
//    init(scents: [Scent]) {
//        self.catalog = Dictionary(uniqueKeysWithValues: scents.map { ($0.id, $0) })
//        self.order = scents.map(\.id)
//        var intensities: [UUID: Double] = [:]
//        for s in scents { intensities[s.id] = s.defaultIntensity }
//        self.mix = Mix(selected: [], intensity: intensities, focused: nil)
//    }
//
//    // MARK: - Intents
//
//    func toggle(_ id: UUID) {
//        if mix.selected.contains(id) {
//            mix.selected.remove(id)
//            if mix.focused == id { mix.focused = nil }
//        } else {
//            guard mix.selected.count < AppConfig.maxSelected else { return }
//            mix.selected.insert(id)
//            mix.focused = id
//        }
//    }
//
//    func setFocused(_ id: UUID?) {
//        mix.focused = id
//    }
//
//    func setIntensity(_ id: UUID, _ value: Double) {
//        let clamped = min(AppConfig.maxIntensity, max(AppConfig.minIntensity, value))
//        mix.intensity[id] = clamped
//    }
//
//    // Utility accessors
//    func intensity(for id: UUID) -> Double {
//        mix.intensity[id] ?? (catalog[id]?.defaultIntensity ?? 0)
//    }
//
//    var selectedIsAtCap: Bool { mix.selected.count >= AppConfig.maxSelected }
//}
