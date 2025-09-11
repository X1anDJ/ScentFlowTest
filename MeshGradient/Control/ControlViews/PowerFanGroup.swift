import SwiftUI

/// Parent hierarchy control: shows a power button; when on, a fan slider appears.
struct PowerFanGroup: View {
    let isOn: Bool
    let speed: Double            // 0...1
    let onToggle: () -> Void
    let onChangeSpeed: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Power button
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: isOn ? "power.circle.fill" : "power")
                        .font(.system(size: 20, weight: .semibold))
                    Text(isOn ? "Device On" : "Device Off")
                        .font(.subheadline)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            if isOn {
                HStack(spacing: 10) {
                    Image(systemName: "fan")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 24, alignment: .center)
                        .accessibilityHidden(true)

                    Slider(value: Binding(
                        get: { speed },
                        set: { onChangeSpeed(min(1, max(0, $0))) }
                    ), in: 0...1)
                    .accessibilityLabel("Fan speed")

                    Text("\(Int(speed * 100))%")
                        .font(.footnote.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Power and fan controls")
    }
}
