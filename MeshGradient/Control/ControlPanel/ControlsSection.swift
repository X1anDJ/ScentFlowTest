//
//  ControlsSection.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/24/25.
//

import SwiftUI

// MARK: - Controls content (no outer CardContainer)
struct ControlsSection: View {

    private enum ControlsUI {
        static let opacityRowHeight: CGFloat = 30   // collapsed row height target
    }

    // MARK: - Parent (Device) — values + intents (no bindings here)
    let isPowerOn: Bool
    let fanSpeed: Double
    let onTogglePower: () -> Void
    let onChangeFanSpeed: (Double) -> Void

    // MARK: - Child (Scents)
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let focusedName: String?
    let canSelectMore: Bool
    let opacities: [String: Double]
    let onTapHue: (String) -> Void
    let onChangeOpacity: (_ name: String, _ value: Double) -> Void

    /// Notify parent when the scents child card expands/collapses,
    /// so the parent can shrink/overlap the circle accordingly.
    var onExpansionChange: (Bool) -> Void = { _ in }

    // UI
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            // Parent: Power + Fan
            PowerButtonRow(
                isOn: isPowerOn,
                speed: fanSpeed,
                onToggle: onTogglePower,
                onChangeSpeed: onChangeFanSpeed
            )

            // Child: Scents
            ChildCard(
                title: "Pods",
                // Make header tappable only if we can actually expand/collapse
                onHeaderTap: (included.count > 1 ? { toggleExpanded() } : nil),
                trailing: {
                    if included.count > 1 {
                        chevronLabel // decorative; header handles taps
                    }
                }
            ) {
                VStack(spacing: 16) {
                    // Hue chips row
                    ScentPodsRow(
                        names: names,
                        colorDict: colorDict,
                        included: included,
                        focusedName: focusedName,
                        canSelectMore: canSelectMore,
                        onTap: onTapHue
                    )

                    if !isExpanded {
                        if included.isEmpty {
                            // Placeholder keeps the card’s folded height stable
                            Text("No active pods. Tap a pod to add.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: ControlsUI.opacityRowHeight, alignment: .center)
                                .accessibilityLabel("No scents added. Tap a pod to add a scent.")
                        } else if let f = focusedName {
                            let focusedScent = Scent(
                                name: f,
                                color: colorDict[f] ?? .gray,
                                defaultIntensity: 0
                            )
                            let binding = Binding<Double>(
                                get: { opacities[f] ?? 0 },
                                set: { onChangeOpacity(f, $0) }
                            )
                            ScentControllerStepper(focused: focusedScent, value: binding)
                                .frame(minHeight: ControlsUI.opacityRowHeight, alignment: .center)
                        } else {
                            // Keep folded height stable even if focusedName is nil
                            Spacer()
                                .frame(minHeight: ControlsUI.opacityRowHeight)
                        }
                    }

                    // Expanded: per-scent rows with sliders
                    if isExpanded {
                        if included.count > 1 {
                            VStack(spacing: 10) {
                                ForEach(names.filter { included.contains($0) }, id: \.self) { name in
                                    ScentControllerSlider(
                                        name: name,
                                        color: colorDict[name] ?? .gray,
                                        displayed: displayed(from: opacities[name] ?? 0),
                                        onChangeDisplayed: { newDisplayed in
                                            let applied = newDisplayed * AppConfig.maxIntensity
                                            onChangeOpacity(name, applied)
                                        },
                                        onFocusOrToggle: { onTapHue(name) }
                                    )
                                }
                            }
                        } else {
                            // Header will immediately collapse via onChange; this is a tiny guard
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
        .onChange(of: included.count) { newCount in
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

// MARK: - Nested “child card” shell (scoped to this file; not reused elsewhere)
private struct ChildCard<Content: View, Trailing: View>: View {
    let title: String
    private let trailingBuilder: () -> Trailing
    @ViewBuilder var content: Content

    // NEW: optional header tap
    let onHeaderTap: (() -> Void)?

    init(
        title: String,
        onHeaderTap: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onHeaderTap = onHeaderTap
        self.trailingBuilder = trailing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            content
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.7)
                .blendMode(.overlay)
        )
    }

    @ViewBuilder
    private var header: some View {
        // Entire header is tappable; trailing is decorative (no hit testing)
        HStack {
            Text(title)
                .font(.subheadline.bold())
            Spacer()
            trailingBuilder()
                .allowsHitTesting(false)
        }
       // .padding(.vertical, 8) // larger hit target
        .contentShape(Rectangle())
        .onTapGesture {
            onHeaderTap?()
        }
        // Accessibility: expose the header as a single button when tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityHeaderLabel)
        .accessibilityAddTraits(onHeaderTap == nil ? [] : .isButton)
    }

    private var accessibilityHeaderLabel: String {
        // Helpful for VO users when the chevron is decorative
        // Example: "Pods, Expand" or "Pods, Collapse"
        guard let onHeaderTap else { return title }
        // We can't know expanded state here cleanly; keep generic
        // If you want the exact state, pass a `stateDescription` in init.
        return title
    }
}
