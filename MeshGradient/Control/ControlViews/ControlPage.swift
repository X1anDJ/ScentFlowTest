import SwiftUI

struct ControlPage: View {
    @StateObject private var vm = GradientWheelViewModel()
    @StateObject private var devices = DevicesStore()
    
    // Sheets
    @State private var showScanner = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Menu {
                    // Devices section
                    Section("My Devices") {
                        ForEach(devices.devices) { device in
                            Button {
                                // Switch device and load its settings into the VM
                                devices.select(device.id)
                                vm.isPowerOn = device.settings.isPowerOn
                                vm.fanSpeed  = device.settings.fanSpeed
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "macmini.fill")
                                    Text(device.name)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                    
                    // Add device section
                    Section("Add Device") {
                        Button { showScanner = true } label: {
                            Label("Add Device", systemImage: "qrcode.viewfinder")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "macmini.fill")
                        Text(devices.selected?.name ?? "No device")
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                }
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                
                // Wheel (off when power is off)
                GradientContainerCircle(
                    colors: vm.selectedColorsWeighted,
                    animate: vm.isPowerOn,
                    meshOpacity: vm.wheelOpacity,
                    isOn: vm.isPowerOn,
                    onToggle: { vm.togglePower() }
                )
                .frame(width: 220, height: 220)
                .padding(.vertical, 36)
                
                
                // Controls (power + fan + scents)
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
                
                // Templates
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
        
        // Sync per-device settings
        .onChange(of: vm.isPowerOn) { _, new in
            devices.updateCurrentSettings(.init(isPowerOn: new, fanSpeed: vm.fanSpeed))
        }
        .onChange(of: vm.fanSpeed) { _, new in
            devices.updateCurrentSettings(.init(isPowerOn: vm.isPowerOn, fanSpeed: new))
        }
        
        // Initial sync
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
