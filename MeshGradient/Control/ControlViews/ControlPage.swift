import SwiftUI

struct ControlPage: View {
    // MARK: - Tunables
    private enum UI {
        static let baseWheelSize: CGFloat  = 220
        static let baseVPadding: CGFloat   = 24
        static let expandedScale: CGFloat  = 0.70    // shrink to 70% when child expands
        static let collapsedScale: CGFloat = 1.00
        static let overlapOffset: CGFloat  = -14     // allow gentle overlap when expanded
        static let cardHPad: CGFloat       = 16
        static let cardBottomPad: CGFloat  = 22
    }

    @StateObject private var vm = GradientWheelViewModel()
    @StateObject private var devices = DevicesStore()

    @State private var showScanner = false

    // Pager state: 0 = Controls, 1 = Templates
    @State private var pageIndex: Int? = 0   // <-- make optional to satisfy `.scrollPosition(id:)`

    // ControlsCard expansion state lifted up from child
    @State private var controlsExpanded: Bool = false

    var body: some View {
        GeometryReader { proxy in
            // Compute dynamic scale & vertical spacing
            let wheelScale = controlsExpanded ? UI.expandedScale : UI.collapsedScale
            let topPadding = UI.baseVPadding
            let allowOverlap = controlsExpanded

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

                // Gradient circle (shrinks when scents child unfolds)
                ZStack {
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
                }
                .frame(maxWidth: .infinity)
                .padding(.top, topPadding)

                // Pager dot indicator (outside the card, above it)
                HStack(spacing: 8) {
                    ForEach(0..<2) { i in
                        Circle()
                            .frame(width: 6, height: 6)
                            .opacity((pageIndex ?? 0) == i ? 1.0 : 0.3) // compare using coalesced value
                            .animation(.easeInOut(duration: 0.2), value: pageIndex)
                    }
                }
                .padding(.top, 6)

                // Cards pager (no ScrollView; swipe to switch between two cards)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 0) {
                        // Page 0: Controls
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
                            onChangeOpacity: { name, eff in vm.setOpacity(eff, for: name) },
                            onExpansionChange: { expanded in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    controlsExpanded = expanded
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .containerRelativeFrame(.horizontal)
                        .id(0)

                        // Page 1: Templates
                        TemplatesCard(
                            names: vm.canonicalOrder,
                            colorDict: vm.colorDict,
                            included: vm.included,
                            opacities: vm.opacities,
                            onApplyTemplate: { inc, ops in vm.applyTemplate(included: inc, opacities: ops) }
                        )
                        .containerRelativeFrame(.horizontal)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .id(1) // distinct id
                    }
                    .scrollTargetLayout()

                }
                .contentMargins(.horizontal, UI.cardHPad, for: .scrollContent)
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $pageIndex)
                .padding(.bottom, UI.cardBottomPad)
                // allow circle + card overlap if expanded and vertical space is tight
                .padding(.top, allowOverlap ? UI.overlapOffset : 0)
                
            }
//
//            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
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

#Preview {
    ControlPage().preferredColorScheme(.dark)
}
