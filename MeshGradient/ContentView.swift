// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GradientWheelViewModel()

    var body: some View {
        TabView {
            // TAB 1: Mix (current functionality) with a navigation title
            NavigationStack {
                MixPage(vm: vm)
            }
            .tabItem {
                Image(systemName: "circle.grid.3x3.fill")
                Text("Mix")
            }

            // TAB 2: Placeholder for future expansion
            NavigationStack {
                VStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 48))
                    Text("Second Tab")
                        .font(.headline)
                    Text("Add whatever you want here later.")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .navigationTitle("More")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "rectangle.grid.2x2")
                Text("More")
            }
        }
    }
}

/// First tab: gradient wheel + the decoupled cards
private struct MixPage: View {
    @ObservedObject var vm: GradientWheelViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Center wheel. When power is OFF we pass [] so the glassy empty circle shows.
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height) * 0.65

                    ZStack {

                        //Add shadow if wanted in the future
                        
                        GradientContainerCircle(colors: vm.isPowerOn ? vm.selectedColorsWeighted : [])
                            .frame(width: side, height: side)

                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .frame(height: UIScreen.main.bounds.height * 0.45)
                .ignoresSafeArea(.keyboard)

                // Controls card (parent + child hierarchy inside)
                ControlsCard(
                    // device (parent)
                    isPowerOn: vm.isPowerOn,
                    fanSpeed: vm.fanSpeed,
                    onTogglePower: { vm.togglePower() },
                    onChangeFanSpeed: { vm.setFanSpeed($0) },

                    // scents (child)
                    names: vm.canonicalOrder,
                    colorDict: vm.colorDict,
                    included: vm.included,
                    focusedName: vm.focusedName,
                    canSelectMore: vm.canSelectMore,
                    opacities: vm.opacities,
                    onTapHue: { vm.toggle($0) },
                    onChangeOpacity: { name, value in vm.setOpacity(value, for: name) }
                )

                // Templates card
                TemplatesCard(
                    names: vm.canonicalOrder,
                    colorDict: vm.colorDict,
                    included: vm.included,
                    opacities: vm.opacities,
                    onApplyTemplate: { included, opacities in
                        vm.applyTemplate(included: included, opacities: opacities)
                    }
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle("ScentFlow")
//        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
