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
        static let collapsedCardHeight: CGFloat = 318
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
    private func persist(_ settings: GradientWheelViewModel.WheelSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            app.devicesService.saveSettingsBlobForSelected(data)
        }
    }

    // Apply selected device’s pods + (optional) saved settings into the VM
    private func loadDeviceIntoVM(_ device: Device) {
        vm.updateDevicePods(device.insertedPods)
        if let blob = device.savedSettingsBlob,
           let currentDeviceSetting = try? JSONDecoder().decode(GradientWheelViewModel.WheelSettings.self, from: blob) {
            vm.load(from: currentDeviceSetting)
        } else {
            // RESET to clean defaults for this *device*
            vm.applyTemplate(nil, on: device)     // clears included + focus
//            vm.setFanSpeed(0.5)                   // or your preferred default
//            vm.clearAllOpacities()                // <-- add this small VM API (see B)
            persist(vm.exportSettings())
        }
    }

    var body: some View {
        ZStack {
            // TOP
            VStack(spacing: 12) {
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
//        .onChange(of: vm.isPowerOn)    { _, _ in saveSnapshot() }
//        .onChange(of: vm.fanSpeed)     { _, _ in saveSnapshot() }
//        .onChange(of: vm.included)     { _, _ in saveSnapshot() }
//        .onChange(of: vm.opacities)    { _, _ in saveSnapshot() }
//        .onChange(of: vm.focusedPodID) { _, _ in saveSnapshot() }
        .onReceive(vm.settingsPublisher) { settings in
            persist(settings)
        }
        // Initial load using .task (cancel-aware).
        .task {
            await app.templatesService.load()
            await app.devicesService.load()

            if let current = app.devicesService.selected ?? app.devicesService.devices.first {
                app.devicesService.select(current.id)
                loadDeviceIntoVM(current)
            }
        }

        // If selection changes elsewhere, rebuild the VM here.
        .task(id: app.devicesService.selectedID) {
            if let current = app.devicesService.selected {
                loadDeviceIntoVM(current)
            }
        }
    }
}
