// ControlsSection.swift  — FIXED call to ScentControllerStepper + ID-centric

import SwiftUI

// MARK: - Controls content (no outer CardContainer)
struct ControlsSection: View {
    @ObservedObject var vm: GradientWheelViewModel
    var onExpansionChange: (Bool) -> Void = { _ in }

    private enum ControlsUI {
        static let opacityRowHeight: CGFloat = 30   // collapsed row height target
    }

    // UI
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {

            // Parent: Power + Fan
            PowerButtonRow(
                isOn: vm.isPowerOn,
                speed: vm.fanSpeed,
                onToggle: { vm.togglePower() },
                onChangeSpeed: { vm.setFanSpeed($0) }
            )

            // Child: Pods
            ChildCard(
                title: "Pods",
                // Make header tappable only if we can actually expand/collapse
                onHeaderTap: (vm.included.count > 1 ? { toggleExpanded() } : nil),
                trailing: {
                    if vm.included.count > 1 {
                        chevronLabel // decorative; header handles taps
                    }
                }
            ) {
                VStack(spacing: 16) {

                    // ID-based chips row
                    ScentPodsRow(
                        pods: vm.pods,
                        includedIDs: vm.included,
                        focusedID: vm.focusedPodID,
                        canSelectMore: vm.canSelectMore,
                        onTap: { vm.toggle($0) }
                    )

                    if !isExpanded {
                        if vm.included.isEmpty {
                            // Placeholder keeps the card’s folded height stable
                            Text("No active pods. Tap a pod to add.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: ControlsUI.opacityRowHeight, alignment: .center)
                                .accessibilityLabel("No scents added. Tap a pod to add a scent.")
                        } else if let fid = vm.focusedPodID,
                                  let pod = vm.pods.first(where: { $0.id == fid }) {
                            // ✅ FIX: ScentControllerStepper takes (focused:value:)
                            let binding = Binding<Double>(
                                get: { vm.opacities[fid] ?? 0 },
                                set: { vm.setOpacity($0, for: fid) }
                            )
                            ScentControllerStepper(
                                focused: pod,
                                value: binding
                            )
                            .frame(minHeight: ControlsUI.opacityRowHeight, alignment: .center)
                        } else {
                            // Keep folded height stable even if focused is nil
                            Spacer()
                                .frame(minHeight: ControlsUI.opacityRowHeight)
                        }
                    }

                    // Expanded: per-scent rows with sliders
                    if isExpanded {
                        if vm.included.count > 1 {
                            VStack(spacing: 10) {
                                ForEach(vm.pods.filter { vm.included.contains($0.id) }, id: \.id) { pod in
                                    let displayed = displayed(from: vm.opacities[pod.id] ?? 0)
                                    ScentControllerSlider(
                                        name: pod.name,
                                        color: pod.color.color,
                                        displayed: displayed,
                                        onChangeDisplayed: { newDisplayed in
                                            let applied = newDisplayed * AppConfig.maxIntensity
                                            vm.setOpacity(applied, for: pod.id)
                                        },
                                        onFocusOrToggle: { vm.toggle(pod.id) }
                                    )
                                }
                            }
                        } else {
                            // Header will immediately collapse via onChange; tiny guard
                            Spacer()
                                .frame(height: ControlsUI.opacityRowHeight)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 16)
        .onAppear {
            // Ensure parent knows the initial state
            onExpansionChange(isExpanded)
        }
        // Auto-collapse when pods drop to 1 or 0 while expanded
        .onChange(of: vm.included.count) { newCount in
            guard isExpanded, newCount <= 1 else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isExpanded = false
                onExpansionChange(false)
            }
        }
    }

    // MARK: - Header chevron (decorative)
    private var chevronLabel: some View {
        Label(isExpanded ? "Collapse" : "Expand",
              systemImage: isExpanded ? "chevron.up" : "chevron.down")
            .labelStyle(.iconOnly)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true) // header is the a11y button
    }

    // MARK: - Toggle helper
    private func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isExpanded.toggle()
            onExpansionChange(isExpanded)
        }
    }

    private func displayed(from effective: Double) -> Double {
        // Convert stored effective (0...maxIntensity) to slider percent (0...1)
        let maxI = max(0.0001, AppConfig.maxIntensity)
        return min(1.0, max(0.0, effective / maxI))
    }
}
