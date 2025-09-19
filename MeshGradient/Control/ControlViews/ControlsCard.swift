import SwiftUI

struct ControlsCard: View {
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

    // UI
    @State private var isExpanded = false

    var body: some View {
        // Use explicit trailing builder so generics always infer
        CardContainer(title: "Controls", trailing: { EmptyView() }) {
            //Divider().opacity(0.6)
            VStack(spacing: 16) {
                // Parent: Power + Fan (matches your PowerFanGroup API)
                PowerFanGroup(
                    isOn: isPowerOn,
                    speed: fanSpeed,
                    onToggle: onTogglePower,
                    onChangeSpeed: onChangeFanSpeed
                )

                // Child: Scents
                ChildCard(title: "Pods", trailing: { childExpandButton }) {
                    VStack(spacing: 16) {
                        // Hue chips row; 3-state is handled in vm.toggle(name)
                        HueCircles(
                            names: names,
                            colorDict: colorDict,
                            included: included,
                            focusedName: focusedName,
                            canSelectMore: canSelectMore,
                            onTap: onTapHue
                        )

                        // Collapsed: single slider for focused scent
                        if !isExpanded, let f = focusedName {
                            // Build a lightweight Scent for the control's label/color
                            let focusedScent = Scent(
                                name: f,
                                color: colorDict[f] ?? .gray,
                                defaultIntensity: 0
                            )

                            // Bridge current effective value <-> callback as a Binding<Double>
                            let binding = Binding<Double>(
                                get: { opacities[f] ?? 0 },
                                set: { onChangeOpacity(f, $0) }
                            )

                            OpacityControl(
                                focused: focusedScent,
                                value: binding
                            )
                        }

                        // Expanded: per-scent rows with sliders
                        if isExpanded && !included.isEmpty {
                            VStack(spacing: 10) {
//                                HStack {
//                                    Text("Active Scents")
//                                        .font(Font.caption)
//                                    Spacer()
//                                }
                            
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
    }

    private var childExpandButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isExpanded.toggle()
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
                    .font(.headline)
                Spacer()
                trailingBuilder()
            }
            content
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

