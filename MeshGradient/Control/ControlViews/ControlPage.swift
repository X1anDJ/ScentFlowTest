import SwiftUI
struct ControlPage: View {
    
    // MARK: - Tunables
    private enum UI {
        static let wheelPadding: CGFloat    = 94
        static let baseVPadding: CGFloat    = 24
        static let expandedScale: CGFloat   = 0.80
        static let collapsedScale: CGFloat  = 1.00
        static let cardHPad: CGFloat        = 16
        static let cardBottomPad: CGFloat   = 16
        static let cardMaxHeight: CGFloat?  = nil
        static let collapsedCardHeight: CGFloat = 310
    }


    @StateObject private var vm = GradientWheelViewModel()
    @StateObject private var devices = DevicesStore()
    @StateObject private var templatesStore = TemplatesStore()

    @State private var showScanner = false

    // ControlsCard expansion state lifted up from child
    @State private var controlsExpanded: Bool = false

    // Segmented control
    private enum Segment: Int, Hashable {
        case controls = 0, templates = 1
    }
    @State private var segment: Segment = .controls

    private func saveSnapshot() {
        devices.updateCurrentSettings(vm.snapshot())
    }
    
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
                                    vm.load(from: device.settings)
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
                    .aspectRatio(1, contentMode: .fit)   // keeps it square
                    .padding(.horizontal, UI.wheelPadding)
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
                                        withAnimation(.spring(response: 0.65, dampingFraction: 0.9)) {
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
                                    },
                                    store: templatesStore
                                )
                            }
                        }
                        .id(segment)
                        
                        // Hug the child's intrinsic height when expanded
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, UI.cardHPad)
                    .padding(.bottom, UI.cardBottomPad)
//                    .padding(.top, shouldAutoSize ? UI.overlapOffset : 0) // allow overlap only when expanded
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    // Default: fixed height. Expanded: let SwiftUI compute intrinsic height.
                    .frame(height: shouldAutoSize ? nil : UI.collapsedCardHeight, alignment: .bottom)
                    .shadow(radius: 6)
                    .animation(.spring(response: 0.65, dampingFraction: 0.8), value: shouldAutoSize)
                }


            }
        }
        .navigationTitle("ScentsFlow")
        .sheet(isPresented: $showScanner) { ScannerSheet() }

        .onChange(of: vm.isPowerOn) { _, _ in saveSnapshot() }
        .onChange(of: vm.fanSpeed)  { _, _ in saveSnapshot() }
        .onChange(of: vm.included)  { _, _ in saveSnapshot() }
        .onChange(of: vm.opacities) { _, _ in saveSnapshot() }
        .onChange(of: vm.focusedName) { _, _ in saveSnapshot() }
        .onAppear {
            if let current = devices.selected {
                vm.load(from: current.settings) // load all on first show
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
