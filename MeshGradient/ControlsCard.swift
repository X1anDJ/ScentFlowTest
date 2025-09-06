import SwiftUI

struct ControlsCard: View {
    // MARK: - Parent (Device)
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

    @State private var isExpanded = false

    var body: some View {
        CardContainer(title: "Controls") {
            VStack(spacing: 16) {

                // Parent hierarchy: Power + (revealed) Fan
                PowerFanGroup(
                    isOn: isPowerOn,
                    speed: fanSpeed,
                    onToggle: onTogglePower,
                    onChangeSpeed: onChangeFanSpeed
                )

                // Child hierarchy: Scents (nested sub-card)
                ChildCard(title: "Scents", trailing: childExpandButton) {
                    VStack(spacing: 16) {
                        // hue chips row
                        HueCircles(
                            names: names,
                            colorDict: colorDict,
                            included: included,
                            focusedName: focusedName,
                            canSelectMore: canSelectMore,
                            onTap: onTapHue
                        )
                        

                        // single slider (collapsed)
                        if !isExpanded, let f = focusedName {
                            OpacityControl(
                                focusedName: f,
                                isFocusedIncluded: included.contains(f),
                                value: opacities[f] ?? 0,
                                onChange: { name, sliderVal in
                                    onChangeOpacity(name, sliderVal)
                                }
                            )
                        }

                        // Expanded per-scent rows
                        if isExpanded {
                            VStack(spacing: 12) {
                                ForEach(names.filter { included.contains($0) }, id: \.self) { name in
                                    ColorRow(
                                        name: name,
                                        color: colorDict[name] ?? .gray,
                                        value: displayed(from: opacities[name] ?? 0),
                                        onChange: { newDisplayed in
                                            let applied = newDisplayed * AppConfig.maxIntensity
                                            onChangeOpacity(name, applied)
                                        },
                                        onTapChip: { onTapHue(name) }
                                    )
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
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
            Label(isExpanded ? "Collapse" : "Expand", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(isExpanded ? "Collapse scent controls" : "Expand scent controls")
    }

    private func displayed(from effective: Double) -> Double {
        let maxI = max(0.0001, AppConfig.maxIntensity)
        return min(1.0, max(0.0, effective / maxI))
    }
}

// MARK: - Nested “child card” shell
private struct ChildCard<Content: View>: View {
    let title: String
    let trailing: AnyView?
    let content: () -> Content

    init(title: String, trailing: some View = EmptyView(), @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.trailing = AnyView(trailing)
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                trailing
            }

            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 0.7)
                        .blendMode(.overlay)
                )
        )
    }
}

// MARK: - One row for an included scent (chip + slider + %)
private struct ColorRow: View {
    let name: String
    let color: Color
    @State var value: Double // 0...1
    let onChange: (Double) -> Void
    let onTapChip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Chip (tap to toggle/remove/focus via VM rules)
            Button(action: onTapChip) {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 0.8).blendMode(.overlay))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            

            VStack(alignment: .leading, spacing: 4) {
                // UPDATED: show "<Color> Scent"
                Text("\(name) Scent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Slider(value: Binding(
                    get: { value },
                    set: { newVal in
                        value = newVal
                        onChange(newVal)
                    }
                ), in: 0...1)
            }

            Text(String(format: "%.0f%%", (value * 100).rounded()))
                .font(.footnote.monospacedDigit())
                .frame(width: 44, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.7)
                        .blendMode(.overlay)
                )
        )
        
    }
}
