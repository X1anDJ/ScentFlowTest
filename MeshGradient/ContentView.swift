import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GradientWheelViewModel()

    var body: some View {
        TabView {
            // MIX
            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {
                        // Wheel (off when power is off)
                        GradientContainerCircle(colors: vm.isPowerOn ? vm.selectedColorsWeighted : [])
                            .frame(width: 240, height: 240)
                            .padding(.vertical, 32)

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

                        // Templates (your existing API)
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
                .navigationTitle("ScentsFlow") // ✅ restored nav title
            }
            .tabItem {
                Image(systemName: "circle.grid.3x3.fill")
                Text("Mix")
            }

            // SECOND TAB (placeholder)
            NavigationStack {
                Text("More coming soon")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Explore")
            }
            .tabItem {
                Image(systemName: "sparkles")
                Text("Explore")
            }
        }
    }
}

#Preview {
    ContentView().preferredColorScheme(.dark)
}
