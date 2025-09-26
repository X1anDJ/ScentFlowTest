import SwiftUI

struct ControlPageSegmentPanel: View {
    @ObservedObject var vm: GradientWheelViewModel
    @ObservedObject var templatesStore: TemplatesStore

    @Binding var segment: ControlPage.Segment
    @Binding var controlsExpanded: Bool

    let collapsedHeight: CGFloat

    private var shouldAutoSize: Bool {
        segment == .controls && controlsExpanded
    }

    var body: some View {
        ZStack {
            // If you ever want a custom background later, add it here.

            VStack {
                Picker("", selection: $segment) {
                    Text("Controls").tag(ControlPage.Segment.controls)
                    Text("Templates").tag(ControlPage.Segment.templates)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 16)

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
                                controlsExpanded = expanded
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
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        // Moved from PanelContainer:
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 16, style: .continuous))

        // Default: fixed height. Expanded: hug intrinsic height.
        .frame(height: shouldAutoSize ? nil : collapsedHeight, alignment: .bottom)
        .animation(.bouncy, value: shouldAutoSize)
    }
}
