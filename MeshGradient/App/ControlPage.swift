// ControlPage.swift — per-device settings + VM hookup

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

    // MARK: - View Model & Stores
    @StateObject private var vm = GradientWheelViewModel()

    // Injected stores
    @ObservedObject var devices: DevicesStore
    @ObservedObject var templatesStore: TemplatesStore

    // MARK: - UI State
    @State private var showScanner = false
    @State private var controlsExpanded = false

    enum Segment: Int, Hashable { case controls = 0, templates = 1 }
    @State private var segment: Segment = .controls

    private var wheelScale: CGFloat { controlsExpanded ? UI.expandedScale : UI.collapsedScale }

    // Persist per-device (not global)
    private func saveSnapshot() {
        devices.updateCurrentSettings(vm.exportSettings())
    }

    var body: some View {
        ZStack {
            // TOP
            VStack(spacing: 12) {
                DeviceMenuBar(
                    devices: devices,
                    showScanner: $showScanner,
                    onSelect: { device in
                        devices.select(device.id)
                        vm.updateDevicePods(device.insertedPods)
                        if let saved = device.savedSettings {
                            vm.load(from: saved)
                        } else {
                            // default: power on, clear wheel
                            vm.setPower(true)
                            // optional: vm.applyTemplate(nil, on: device)
                        }
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
                    templatesStore: templatesStore,
                    devicesStore: devices,
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
        //.navigationTitle("ScentsFlow")
        //.navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) { ScannerSheet() }

        // Persist per-device on changes
        .onChange(of: vm.isPowerOn)    { _, _ in saveSnapshot() }
        .onChange(of: vm.fanSpeed)     { _, _ in saveSnapshot() }
        .onChange(of: vm.included)     { _, _ in saveSnapshot() }
        .onChange(of: vm.opacities)    { _, _ in saveSnapshot() }
        .onChange(of: vm.focusedPodID) { _, _ in saveSnapshot() }

        // Initial load
        .onAppear {
            if let current = devices.selected {
                // 1) pods drive colors/order
                vm.updateDevicePods(current.insertedPods)
                // 2) load saved settings for this device if any
                if let saved = current.savedSettings {
                    vm.load(from: saved)
                } else {
                    vm.setPower(true)
                }
            } else {
                // If no device yet, seed a mock and initialize
                devices.seedMockIfNeeded()
                if let current = devices.selected {
                    vm.updateDevicePods(current.insertedPods)
                    vm.setPower(true)
                }
            }
        }
        
    }
}
