import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GradientWheelViewModel()
    @StateObject private var devices = DevicesStore()

    // Sheets
    @State private var showScanner = false
    @State private var showDevicePicker = false

    var body: some View {
        TabView {
            // MIX
            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {

                        // ⬇️ Current device label (under the title)
                        HStack(spacing: 6) {
                            Image(systemName: "macmini.fill")
                            Text(devices.selected?.name ?? "No device")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                        // Wheel (off when power is off)
                        GradientContainerCircle(colors: vm.isPowerOn ? vm.selectedColorsWeighted : [])
                            .frame(width: 224, height: 224)
                            .padding(.vertical, 48)
                        
                        

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
                }
                .navigationTitle("ScentsFlow")
                .toolbar {
                    // 1) Scan to add a device
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showScanner = true
                        } label: {
                            Label("Add Device", systemImage: "qrcode.viewfinder")
                        }
                    }
                    // 2) Device options / switcher
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showDevicePicker = true
                        } label: {
                            Label(devices.selected?.name ?? "Device", systemImage: "arrow.left.arrow.right")
                        }
                    }
                }
                .sheet(isPresented: $showScanner) {
                    ScannerSheet()
                }
                .sheet(isPresented: $showDevicePicker) {
                    DevicePickerSheet(store: devices) { picked in
                        // Load the picked device’s settings into the VM
                        vm.isPowerOn = picked.settings.isPowerOn
                        vm.fanSpeed  = picked.settings.fanSpeed
                    }
                }
                // Keep per-device settings in sync when user changes them
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
            .tabItem {
                Image(systemName: "circle.hexagonpath.fill")
                Text("Control")
            }

            // SECOND TAB (placeholder)
            NavigationStack {
                ExplorePage()
            }
            .tabItem {
                Image(systemName: "sparkles")
                Text("Explore")
            }

            // THIRD TAB (placeholder)
            NavigationStack {
                Text("More coming soon")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("User")
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("User")
            }
        }
    }
}

#Preview {
    ContentView().preferredColorScheme(.dark)
}
