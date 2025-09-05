//
//  PowerFanGroup.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/5/25.
//


import SwiftUI

/// Parent hierarchy control: shows a power button. When powered on,
/// the power button slides left and a fan icon + slider appear to its right.
struct PowerFanGroup: View {
    let isOn: Bool
    let speed: Double            // 0...1 (reserved for later logic)
    let onToggle: () -> Void
    let onChangeSpeed: (Double) -> Void

    @Namespace private var ns

    var body: some View {
        HStack {
            if isOn {
                // Left-aligned power when ON
                powerButton
                    .matchedGeometryEffect(id: "power", in: ns)
                fanControl
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                // Centered power when OFF
                Spacer(minLength: 0)
                powerButton
                    .matchedGeometryEffect(id: "power", in: ns)
                Spacer(minLength: 0)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isOn)
    }

    private var powerButton: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: "power")
                    .font(.system(size: 16, weight: .semibold))
                Text(isOn ? "On" : "Off")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOn ? Color.green.opacity(0.22) : Color.secondary.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 0.8)
                    .blendMode(.overlay)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Turn power off" : "Turn power on")
    }

    private var fanControl: some View {
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
        }
        .padding(.leading, 12)
    }
}
