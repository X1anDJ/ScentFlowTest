import SwiftUI

struct ControlPage: View {
    // MARK: - Tunables
    private enum UI {
        static let maxScroll: CGFloat      = 80     // how many pts of scroll to fully apply effects
        static let shrinkAmount: CGFloat   = 0.20    // 20% shrink at maxScroll (1.0 → 0.8)
        static let baseWheelSize: CGFloat  = 220
        static let baseVPadding: CGFloat   = 36
        static let paddingShrink: CGFloat  = 0.80    // reduce vertical padding up to 70% at maxScroll
    }

    @StateObject private var vm = GradientWheelViewModel()
    @StateObject private var devices = DevicesStore()

    @State private var showScanner = false
    @State private var scrollY: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                Menu {
                    Section("My Devices") {
                        ForEach(devices.devices) { device in
                            Button {
                                devices.select(device.id)
                                vm.isPowerOn = device.settings.isPowerOn
                                vm.fanSpeed  = device.settings.fanSpeed
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "macmini.fill")
                                    Text(device.name).lineLimit(1).truncationMode(.tail)
                                }
                            }
                        }
                    }
                    Section("Add Device") {
                        Button { showScanner = true } label: {
                            Label("Add Device", systemImage: "qrcode.viewfinder")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "macmini.fill")
                        Text(devices.selected?.name ?? "No device")
                            .lineLimit(1).truncationMode(.tail)
                        Spacer()
                    }
                }
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

                // ---- Scroll-driven mapping
                let t      = min(max(scrollY, 0), UI.maxScroll) / UI.maxScroll   // 0…1
                let scale  = 1.0 - UI.shrinkAmount * t                            // 1.0 → (1 - shrinkAmount)
                let vPad   = UI.baseVPadding * (1.0 - UI.paddingShrink * t)       // 36 → ~11 (with paddingShrink=0.7)

                // Wheel
                GradientContainerCircle(
                    colors: vm.selectedColorsWeighted,
                    animate: vm.isPowerOn,
                    meshOpacity: vm.wheelOpacity,
                    isOn: vm.isPowerOn,
                    onToggle: { vm.togglePower() }
                )
                .frame(width: UI.baseWheelSize, height: UI.baseWheelSize)
                .scaleEffect(scale, anchor: .center)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: scale)
                .padding(.vertical, vPad)

                // Controls
                ControlsCard(
                    isPowerOn: vm.isPowerOn,
                    fanSpeed: vm.fanSpeed,
                    onTogglePower: { vm.togglePower() },
                    onChangeFanSpeed: { vm.setFanSpeed($0) },
                    names: vm.canonicalOrder,
                    colorDict: vm.colorDict,
                    included: vm.included,
                    focusedName: vm.focusedName,
                    canSelectMore: vm.canSelectMore,
                    opacities: vm.opacities,
                    onTapHue: { vm.toggle($0) },
                    onChangeOpacity: { name, eff in vm.setOpacity(eff, for: name) }
                )

                // Debug label (optional—remove if you don’t want it)
                Text(String(format: "scrollY: %.0f  |  scale: %.2f  |  vPad: %.1f", scrollY, scale, vPad))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TemplatesCard(
                    names: vm.canonicalOrder,
                    colorDict: vm.colorDict,
                    included: vm.included,
                    opacities: vm.opacities,
                    onApplyTemplate: { inc, ops in vm.applyTemplate(included: inc, opacities: ops) }
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 22)
        }
        .navigationTitle("ScentsFlow")
        .sheet(isPresented: $showScanner) { ScannerSheet() }

        // iOS 18+ contentOffset reader
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newY in
            scrollY = max(0, newY)
        }

        // Keep per-device settings in sync
        .onChange(of: vm.isPowerOn) { _, new in
            devices.updateCurrentSettings(.init(isPowerOn: new, fanSpeed: vm.fanSpeed))
        }
        .onChange(of: vm.fanSpeed) { _, new in
            devices.updateCurrentSettings(.init(isPowerOn: vm.isPowerOn, fanSpeed: new))
        }
        .onAppear {
            if let current = devices.selected {
                vm.isPowerOn = current.settings.isPowerOn
                vm.fanSpeed  = current.settings.fanSpeed
            }
        }
    }
}

#Preview {
    ControlPage().preferredColorScheme(.dark)
}
