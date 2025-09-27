// ControlPageSegmentPanel.swift — matches ControlsSection & TemplatesSection

import SwiftUI

struct ControlPageSegmentPanel: View {
    @ObservedObject var vm: GradientWheelViewModel
    @ObservedObject var templatesStore: TemplatesStore
    @ObservedObject var devicesStore: DevicesStore

    @Binding var segment: ControlPage.Segment
    @Binding var controlsExpanded: Bool

    let collapsedHeight: CGFloat

    private var shouldAutoSize: Bool { segment == .controls && controlsExpanded }

    var body: some View {
        ZStack {
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
                        ControlsSection(vm: vm, onExpansionChange: { controlsExpanded = $0 })

                    case .templates:
                        TemplatesSection(
                            store: templatesStore,
                            vm: vm,
                            device: devicesStore.device
                        )
                    }
                }
                .id(segment)
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(height: shouldAutoSize ? nil : collapsedHeight, alignment: .bottom)
        .animation(.bouncy, value: shouldAutoSize)
    }
}
