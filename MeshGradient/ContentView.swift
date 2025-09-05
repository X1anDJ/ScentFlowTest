import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GradientWheelViewModel()

    var body: some View {
        ZStack {
            // Center: gradient circle in a glassy container
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) * 0.65
                GradientContainerCircle(colors: meshPalette(for: vm.selectedColorsWeighted))
                    .frame(width: side, height: side)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea(.keyboard)

            // Bottom controller sheet
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                BottomControls(
                    names: vm.canonicalOrder,
                    colorDict: vm.colorDict,
                    included: vm.included,
                    focusedName: vm.focusedName,
                    canSelectMore: vm.canSelectMore,
                    opacities: vm.opacities,
                    onTapHue: { vm.toggle($0) },
                    onChangeOpacity: { name, v in vm.setOpacity(v, for: name) },
                    onApplyTemplate: { inc, ops in vm.applyTemplate(included: inc, opacities: ops) }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func meshPalette(for weighted: [Color]) -> [Color] {
        switch weighted.count {
        case 0:  return []
        default: return weighted
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
