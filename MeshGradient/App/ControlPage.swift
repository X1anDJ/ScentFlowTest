//
//  ControlPage.swift — per-device control UI hooked to AppModel/services.
//  - Reads devices/templates via @EnvironmentObject AppModel
//  - Loads a device’s saved wheel settings blob (if any) into the VM on appear/select
//  - Saves wheel changes back to the selected device (encoded as Data) on change
//  - Passes services to your panel views (update their signatures accordingly)
//

import SwiftUI

struct ControlPage: View {

    // MARK: - Tunables
    private enum UI {
        static let wheelPadding: CGFloat    = 80
        static let baseVPadding: CGFloat    = 24
        static let expandedScale: CGFloat   = 0.85
        static let collapsedScale: CGFloat  = 1.00
        static let cardHPad: CGFloat        = 16
        static let cardBottomPad: CGFloat   = 16
        static let collapsedCardHeight: CGFloat = 310
    }

    // MARK: - Environment (new architecture)
    @EnvironmentObject private var app: AppModel

    // MARK: - View Model
    @StateObject private var vm = GradientWheelViewModel()

    // MARK: - UI State
    @State private var showScanner = false
    @State private var controlsExpanded = false

    enum Segment: Int, Hashable { case controls = 0, templates = 1 }
    @State private var segment: Segment = .controls

    private var wheelScale: CGFloat { controlsExpanded ? UI.expandedScale : UI.collapsedScale }

    // Persist per-device (not global): encode VM settings → Data → DevicesService
    private func saveSnapshot() {
        let settings = vm.exportSettings()
        if let data = try? JSONEncoder().encode(settings) {
            app.devicesService.saveSettingsBlobForSelected(data)
        }
    }

    // Apply selected device’s pods + (optional) saved settings into the VM
    private func loadDeviceIntoVM(_ device: Device) {
        // 1) pods drive colors/order
        vm.updateDevicePods(device.insertedPods)

        // 2) load saved settings, else set a sensible default
        if let blob = device.savedSettingsBlob,
           let saved = try? JSONDecoder().decode(GradientWheelViewModel.WheelSettings.self, from: blob) {
            vm.load(from: saved)
        } else {
            vm.setPower(true)
            // optional: vm.applyTemplate(nil, on: device)
        }
    }

    var body: some View {
        ZStack {
            // TOP
            VStack(spacing: 12) {
                // Update your DeviceMenuBar to accept services instead of old stores:
                // DeviceMenuBar(devicesService:..., onSelect:...)
                DeviceMenuBar(
                    devicesService: app.devicesService,
                    showScanner: $showScanner,
                    onSelect: { device in
                        app.devicesService.select(device.id)
                        loadDeviceIntoVM(device)
                    }
                )
                .padding(.top, 4)
                .padding(.leading, 16)

                GradientContainerCircle(
                    colors: vm.selectedColorsWeighted,
                    animate: vm.isPowerOn,
                    meshOpacity: vm.wheelOpacity,
                    isOn: vm.isPowerOn,
                    onToggle: { vm.togglePower() }
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, UI.wheelPadding)
                .scaleEffect(wheelScale, anchor: .center)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: wheelScale)
                .padding(.top, UI.baseVPadding)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // BOTTOM PANEL
            VStack {
                Spacer().frame(minHeight: 30)

                // Update your ControlPageSegmentPanel to take services:
                // ControlPageSegmentPanel(vm:..., templatesService:..., devicesService:...)
                ControlPageSegmentPanel(
                    vm: vm,
                    templatesService: app.templatesService,
                    devicesService: app.devicesService,
                    segment: $segment,
                    controlsExpanded: $controlsExpanded,
                    collapsedHeight: UI.collapsedCardHeight
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, UI.cardHPad)
                .padding(.bottom, UI.cardBottomPad)
                .shadow(radius: 6)
            }
        }
        .sheet(isPresented: $showScanner) { ScannerSheet() }

        // Persist per-device on changes (debounce if needed inside your services)
        .onChange(of: vm.isPowerOn)    { _, _ in saveSnapshot() }
        .onChange(of: vm.fanSpeed)     { _, _ in saveSnapshot() }
        .onChange(of: vm.included)     { _, _ in saveSnapshot() }
        .onChange(of: vm.opacities)    { _, _ in saveSnapshot() }
        .onChange(of: vm.focusedPodID) { _, _ in saveSnapshot() }

        // Initial load
        .onAppear {
            // Ensure local data is loaded (idempotent)
            app.devicesService.load()
            app.templatesService.load()

            if let current = app.devicesService.selected {
                loadDeviceIntoVM(current)
            } else if let first = app.devicesService.devices.first {
                app.devicesService.select(first.id)
                loadDeviceIntoVM(first)
            } else {
                // If no device yet, seed a mock and initialize
                // (DevicesService seeds on load when empty, but this is extra safety)
                app.devicesService.load()
                if let current = app.devicesService.selected ?? app.devicesService.devices.first {
                    loadDeviceIntoVM(current)
                }
            }
        }
    }
}
