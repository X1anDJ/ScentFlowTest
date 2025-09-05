// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GradientWheelViewModel()

    var body: some View {
        TabView {
            // TAB 1: Mix (the current functionality)
            MixPage(vm: vm)
                .tabItem {
                    Image(systemName: "circle.grid.3x3.fill")
                    Text("Mix")
                }

            // TAB 2: Placeholder for future expansion
            VStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 48))
                Text("Second Tab")
                    .font(.headline)
                Text("Add whatever you want here later.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .tabItem {
                Image(systemName: "rectangle.grid.2x2")
                Text("More")
            }
        }
    }
}

/// First tab: gradient wheel + two decoupled cards (Controls + Templates)
private struct MixPage: View {
    @ObservedObject var vm: GradientWheelViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Center wheel
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height) * 0.65
                    GradientContainerCircle(colors: vm.selectedColorsWeighted)
                        .frame(width: side, height: side)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .frame(height: UIScreen.main.bounds.height * 0.45)
                .ignoresSafeArea(.keyboard)

                // Controls (decoupled)
                ControlsCard(
                    names: vm.canonicalOrder,
                    colorDict: vm.colorDict,
                    included: vm.included,
                    focusedName: vm.focusedName,
                    canSelectMore: vm.canSelectMore,
                    opacities: vm.opacities,
                    onTapHue: { vm.toggle($0) }, // <-- no external label
                    onChangeOpacity: { name, value in vm.setOpacity(value, for: name) }
                )

                // Templates (decoupled)
                TemplatesCard(
                    names: vm.canonicalOrder,
                    colorDict: vm.colorDict,
                    included: vm.included,          // <-- pass current mix
                    opacities: vm.opacities,        // <-- pass current mix
                    onApplyTemplate: { included, opacities in
                        vm.applyTemplate(included: included, opacities: opacities)
                    }
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle("Scent Mixer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
