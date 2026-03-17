// ControlsSection.swift  — FIXED call to ScentControllerStepper + ID-centric

//
//  ControlsSection.swift
//

import SwiftUI

struct ControlsSection: View {
    @ObservedObject var vm: GradientWheelViewModel
    @Binding var isExpanded: Bool

    private enum ControlsUI {
        static let opacityRowHeight: CGFloat = 34
    }

    var body: some View {
        VStack(spacing: 16) {

            PowerButtonRow(
                isOn: vm.isPowerOn,
                speed: vm.fanSpeed,
                onToggle: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        vm.togglePower()
                    }
                },
                onChangeSpeed: { vm.setFanSpeed($0) }
            )

            ZStack {
                ChildCard(
                    title: "Pods",
                    onHeaderTap: (
                        vm.isPowerOn && vm.pods.count > 1
                        ? { toggleExpanded() }
                        : nil
                    ),
                    trailing: {
                        if vm.pods.count > 1 {
                            chevronLabel
                        }
                    }
                ) {
                    VStack(spacing: 16) {

                        if !isExpanded {
                            ScentPodsRow(
                                pods: vm.pods,
                                includedIDs: vm.included,
                                focusedID: vm.focusedPodID,
                                canSelectMore: vm.canSelectMore,
                                onTap: { vm.toggle($0) }
                            )
                        }

                        if !isExpanded {
                            if vm.included.isEmpty {
                                Text("No active pods. Tap a pod to add.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(minHeight: ControlsUI.opacityRowHeight, alignment: .center)
                                    .accessibilityLabel("No scents added. Tap a pod to add a scent.")
                            } else if let fid = vm.focusedPodID,
                                      let pod = vm.pods.first(where: { $0.id == fid }) {
                                ScentControllerStepper(
                                    focused: pod,
                                    value: bindingForCollapsedStepper(podID: fid)
                                )
                                .frame(minHeight: ControlsUI.opacityRowHeight, alignment: .center)
                            } else {
                                Spacer()
                                    .frame(minHeight: ControlsUI.opacityRowHeight)
                            }
                        }

                        if isExpanded {
                            VStack(spacing: 10) {
                                ForEach(vm.pods, id: \.id) { pod in
                                    let isIncluded = vm.included.contains(pod.id)
                                    let displayed = displayedValue(for: pod.id)

                                    ScentControllerSlider(
                                        name: pod.name,
                                        color: isIncluded ? pod.color.color : .secondary.opacity(0.35),
                                        displayed: displayed,
                                        onChangeDisplayed: { newDisplayed in
                                            applyExpandedSliderChange(newDisplayed, for: pod.id)
                                        },
                                        onFocusOrToggle: nil,
                                        onRemove: nil,
                                        showsPercentage: true,
                                        isDimmed: !isIncluded
                                    )
                                }
                            }
                        }
                    }
                }
                .disabled(!vm.isPowerOn)
                .opacity(vm.isPowerOn ? 1.0 : 0.45)
                .animation(.easeInOut(duration: 0.2), value: vm.isPowerOn)
            }
        }
        .padding(.bottom, 16)
        .onChange(of: vm.isPowerOn) { _, isOn in
            if !isOn && isExpanded {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    isExpanded = false
                }
            }
        }
        .onChange(of: vm.included.count) { newCount in
            guard isExpanded, newCount <= 1 else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isExpanded = false
            }
        }
    }

    private var chevronLabel: some View {
        Label(
            isExpanded ? "Collapse" : "Expand",
            systemImage: isExpanded ? "chevron.up" : "chevron.down"
        )
        .labelStyle(.iconOnly)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    private func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isExpanded.toggle()
        }
    }

    private func bindingForCollapsedStepper(podID: UUID) -> Binding<Double> {
        Binding<Double>(
            get: { vm.opacities[podID] ?? 0 },
            set: { vm.setOpacity($0, for: podID) }
        )
    }

    private func displayedValue(for podID: UUID) -> Double {
        let effective = vm.opacities[podID] ?? 0
        let maxI = max(0.0001, AppConfig.maxIntensity)
        return min(1.0, max(0.0, effective / maxI))
    }

    private func applyExpandedSliderChange(_ displayed: Double, for podID: UUID) {
        let effective = max(0, min(1, displayed)) * AppConfig.maxIntensity
        let wasIncluded = vm.included.contains(podID)

        if effective <= 0.0001 {
            if wasIncluded {
                vm.toggle(podID)
            } else {
                vm.setOpacity(0, for: podID)
            }
            return
        }

        if !wasIncluded {
            vm.toggle(podID)
        }

        vm.setOpacity(effective, for: podID)
    }
}
