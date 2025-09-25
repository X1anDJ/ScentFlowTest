import SwiftUI

struct ControlPage: View {

    // MARK: - Tunables
    private enum UI {
        static let wheelPadding: CGFloat    = 94
        static let baseVPadding: CGFloat    = 24
        static let expandedScale: CGFloat   = 0.85
        static let collapsedScale: CGFloat  = 1.00
        static let cardHPad: CGFloat        = 16
        static let cardBottomPad: CGFloat   = 16
        static let collapsedCardHeight: CGFloat = 310
    }

    // MARK: - View Model & Stores
    @StateObject private var vm = GradientWheelViewModel()
    @StateObject private var devices = DevicesStore()
    @StateObject private var templatesStore = TemplatesStore()

    // MARK: - UI State
    @State private var showScanner = false
    @State private var controlsExpanded = false

    // Segmented control
    enum Segment: Int, Hashable {
        case controls = 0, templates = 1
    }
    @State private var segment: Segment = .controls

    // MARK: - Computed
    private var wheelScale: CGFloat {
        controlsExpanded ? UI.expandedScale : UI.collapsedScale
    }

    // MARK: - Persistence
    private func saveSnapshot() {
        devices.updateCurrentSettings(vm.snapshot())
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // TOP COLUMN
            VStack(spacing: 12) {
                DeviceMenuBar(
                    devices: devices,
                    showScanner: $showScanner,
                    onSelect: { device in
                        devices.select(device.id)
                        vm.load(from: device.settings)
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
                .aspectRatio(1, contentMode: .fit)   // keeps it square
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
        .navigationTitle("ScentsFlow")
        .sheet(isPresented: $showScanner) { ScannerSheet() }

        // MARK: - State Change Persistence
        .onChange(of: vm.isPowerOn)    { _, _ in saveSnapshot() }
        .onChange(of: vm.fanSpeed)     { _, _ in saveSnapshot() }
        .onChange(of: vm.included)     { _, _ in saveSnapshot() }
        .onChange(of: vm.opacities)    { _, _ in saveSnapshot() }
        .onChange(of: vm.focusedName)  { _, _ in saveSnapshot() }

        // MARK: - Initial Load
        .onAppear {
            if let current = devices.selected {
                vm.load(from: current.settings)
            }
        }
    }
}
