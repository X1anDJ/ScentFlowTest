// ControlsSection.swift  — FIXED call to ScentControllerStepper + ID-centric

//
//  ControlsSection.swift
//
import SwiftUI

struct ControlsSection: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject var vm: GradientWheelViewModel
    let device: Device
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 16) {
            PodsControlView(
                vm: vm,
                isExpanded: $isExpanded
            )

            PowerButtonRow(
                isOn: vm.isPowerOn,
                speed: vm.fanSpeed,
                onToggle: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        vm.togglePower()
                    }
                },
                onChangeSpeed: { vm.setFanSpeed($0) },
                showsTemplateTransport: !app.templatesService.templates.isEmpty,
                canGoPrevious: vm.isUsingTemplate && app.templatesService.canGoPrevious,
                canGoNext: vm.isUsingTemplate && app.templatesService.canGoNext,
                onPrevious: {
                    app.applyPreviousTemplate(to: vm, on: device)
                },
                onNext: {
                    app.applyNextTemplate(to: vm, on: device)
                }
            )
        }
        .padding(.bottom, 16)
    }
}
