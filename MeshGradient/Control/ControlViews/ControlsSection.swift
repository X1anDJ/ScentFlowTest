//
//  ControlsSection.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/24/25.
//


import SwiftUI

// MARK: - Controls content (no outer CardContainer)
struct ControlsSection: View {
    
    // ControlsCard.swift (top of file or just above ControlsSection)
    private enum ControlsUI {
        static let opacityRowHeight: CGFloat = 26   // collapsed row height target
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
            PowerFanGroup(
                isOn: isPowerOn,
                speed: fanSpeed,
                onToggle: onTogglePower,
                onChangeSpeed: onChangeFanSpeed
            )

            // Child: Scents
            ChildCard(title: "Pods", trailing: {
                if included.count > 1 {
                    childExpandButton
                }
                    
                
            }) {
                VStack(spacing: 16) {
                    // Hue chips row
                    HueCircles(
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
                            Text("No active pods")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: ControlsUI.opacityRowHeight, alignment: .center)
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
                            OpacityControl(focused: focusedScent, value: binding)
                                .frame(height: ControlsUI.opacityRowHeight, alignment: .center)
                        }
                    }

                    // Expanded: per-scent rows with sliders
                    if isExpanded  {
                        
                        if included.isEmpty {
                            // Placeholder keeps the card’s folded height stable
                            Text("No active pods")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: ControlsUI.opacityRowHeight, alignment: .center)
                                .accessibilityLabel("No scents added. Tap a pod to add a scent.")
                        } else {
                            VStack(spacing: 10) {
                                ForEach(names.filter { included.contains($0) }, id: \.self) { name in
                                    ColorRow(
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
    }

    private var childExpandButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isExpanded.toggle()
                onExpansionChange(isExpanded)
            }
        } label: {
            Label(isExpanded ? "Collapse" : "Expand",
                  systemImage: isExpanded ? "chevron.up" : "chevron.down")
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(isExpanded ? "Collapse scent controls" : "Expand scent controls")
    }

    private func displayed(from effective: Double) -> Double {
        // Convert stored effective (0...maxIntensity) to slider percent (0...1)
        let maxI = max(0.0001, AppConfig.maxIntensity)
        return min(1.0, max(0.0, effective / maxI))
    }
}

// MARK: - Nested “child card” shell
private struct ChildCard<Content: View, Trailing: View>: View {
    let title: String
    private let trailingBuilder: () -> Trailing
    @ViewBuilder var content: Content

    init(
        title: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailingBuilder = trailing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                trailingBuilder()
            }
            content
            Spacer()
        }
        .padding(12)
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.7)
                .blendMode(.overlay)
        )
    }
}
