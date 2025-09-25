import SwiftUI




struct ControlPage: View {
    
    // MARK: - Tunables
    private enum UI {
        static let baseWheelSize: CGFloat  = 220
        static let baseVPadding: CGFloat   = 24
        static let expandedScale: CGFloat  = 0.80
        static let collapsedScale: CGFloat = 1.00
        static let cardHPad: CGFloat       = 16
        static let cardBottomPad: CGFloat  = 22
        // Optional cap for the card height (set to nil to disable)
        static let cardMaxHeight: CGFloat? = nil
        static let collapsedCardHeight: CGFloat = 400
    }

    @StateObject private var vm = GradientWheelViewModel()
    @StateObject private var devices = DevicesStore()

    @State private var showScanner = false

    // ControlsCard expansion state lifted up from child
    @State private var controlsExpanded: Bool = false

    // Segmented control
    private enum Segment: Int, Hashable {
        case controls = 0, templates = 1
    }
    @State private var segment: Segment = .controls

    var body: some View {
        GeometryReader { _ in
            // Compute dynamic scale & vertical spacing
            let wheelScale = controlsExpanded ? UI.expandedScale : UI.collapsedScale
            let topPadding = UI.baseVPadding

            ZStack( ) {
                // TOP COLUMN fills the space, anchored to top
                VStack(spacing: 12) {
                    // Device menu
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
                    .padding(.leading, 16)

                    GradientContainerCircle(
                        colors: vm.selectedColorsWeighted,
                        animate: vm.isPowerOn,
                        meshOpacity: vm.wheelOpacity,
                        isOn: vm.isPowerOn,
                        onToggle: { vm.togglePower() }
                    )
                    .frame(width: UI.baseWheelSize, height: UI.baseWheelSize)
                    .scaleEffect(wheelScale, anchor: .center)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: wheelScale)
                    .padding(.top, topPadding)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // inside var body: some View, near the bottom card…
                VStack {
                    Spacer().frame(minHeight: 30)

                    let shouldAutoSize = (segment == .controls && controlsExpanded)

                    PanelContainer(title: "", trailing: { EmptyView() }) {
                        Picker("", selection: $segment) {
                            Text("Controls").tag(Segment.controls)
                            Text("Templates").tag(Segment.templates)
                        }
                        .pickerStyle(.segmented)

                        Group {
                            switch segment {
                            case .controls:
                                ControlsSection(
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
                                    onChangeOpacity: { name, eff in vm.setOpacity(eff, for: name) },
                                    onExpansionChange: { expanded in
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                            controlsExpanded = expanded
                                        }
                                    }
                                )

                            case .templates:
                                TemplatesSection(
                                    names: vm.canonicalOrder,
                                    colorDict: vm.colorDict,
                                    included: vm.included,
                                    opacities: vm.opacities,
                                    onApplyTemplate: { inc, ops in
                                        vm.applyTemplate(included: inc, opacities: ops)
                                    }
                                )
                            }
                        }
                        .id(segment)
                        // Hug the child's intrinsic height when expanded
                        //.fixedSize(horizontal: false, vertical: shouldAutoSize)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, UI.cardHPad)
                    .padding(.bottom, UI.cardBottomPad)
//                    .padding(.top, shouldAutoSize ? UI.overlapOffset : 0) // allow overlap only when expanded
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    // Default: fixed height. Expanded: let SwiftUI compute intrinsic height.
                    .frame(height: shouldAutoSize ? nil : UI.collapsedCardHeight, alignment: .bottom)
                    .animation(.spring(response: 0.45, dampingFraction: 0.9), value: shouldAutoSize)
                }


            }
        }
        .navigationTitle("ScentsFlow")
        .sheet(isPresented: $showScanner) { ScannerSheet() }

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

// Helper to optionally cap height without affecting bottom alignment
private struct MaxHeightIfProvided: ViewModifier {
    let max: CGFloat?
    init(_ max: CGFloat?) { self.max = max }
    func body(content: Content) -> some View {
        if let max {
            content.frame(maxHeight: max, alignment: .bottom)
        } else {
            content
        }
    }
}

#Preview {

}
