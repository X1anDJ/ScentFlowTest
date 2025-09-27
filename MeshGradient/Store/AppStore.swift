// AppStore.swift — slim coordinator (no power/fan in CurrentSettings)

import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    let devices: DevicesStore
    let templates: TemplatesStore
    let current: CurrentSettingsStore     // now used for app-wide prefs (activeTemplateID)
    @Published var vm: GradientWheelViewModel
    private var bag = Set<AnyCancellable>()

    init(devices: DevicesStore, templates: TemplatesStore, current: CurrentSettingsStore, vm: GradientWheelViewModel) {
        self.devices = devices
        self.templates = templates
        self.current = current
        self.vm = vm

        templates.load()
        current.load()
        templates.activeTemplateID = current.settings.activeTemplateID

        // React to active template changes only; power is per-device now
        templates.$activeTemplateID
            .removeDuplicates()
            .sink { [weak self] _ in self?.applyActiveTemplateToWheel() }
            .store(in: &bag)
    }

    func setActiveTemplate(_ id: UUID?) {
        templates.activeTemplateID = id
        current.settings.activeTemplateID = id
        current.persist()
        templates.persist()
        applyActiveTemplateToWheel()
    }

    private func applyActiveTemplateToWheel() {
        // Device pods (source of colors/order)
        vm.updateDevicePods(devices.device.insertedPods)

        // Apply active template (intersects with inserted pods, preserves order, sets defaults)
        vm.applyTemplate(templates.activeTemplate, on: devices.device)

        // Persist new wheel snapshot to the selected device
        devices.updateCurrentSettings(vm.exportSettings())
    }
}
