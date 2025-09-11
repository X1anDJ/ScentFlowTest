import SwiftUI
import Combine

/// Optional facade that coordinates your VM and templates persistence.
/// If you're not using AppStore, you can remove this file from the build target.
/// If you keep it, it now matches your string-based model.
@MainActor
final class AppStore: ObservableObject {
    @Published var vm = GradientWheelViewModel()

    private let templatesRepo: TemplatesRepository
    @Published private(set) var templates: [ColorTemplate] = []

    init(templatesRepo: TemplatesRepository = UserDefaultsTemplatesRepository()) {
        self.templatesRepo = templatesRepo
        self.templates = (try? templatesRepo.load()) ?? []
    }

    // Render palette surfaced for convenience (same as ContentView currently does).
    var renderPalette: [Color] {
        vm.isPowerOn ? vm.selectedColorsWeighted : []
    }

    // MARK: - Templates
    func saveCurrentTemplate() {
        let t = ColorTemplate(
            name: "Mix \(templates.count + 1)",
            included: vm.included,
            opacities: vm.opacities
        )
        templates.insert(t, at: 0)
        persist()
    }

    func apply(template: ColorTemplate) {
        vm.applyTemplate(included: template.included, opacities: template.opacities)
    }

    func delete(template: ColorTemplate) {
        templates.removeAll { $0.id == template.id }
        persist()
    }

    private func persist() {
        try? templatesRepo.save(templates)
    }
}
