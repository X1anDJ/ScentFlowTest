//
//  PowerButtonRow.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//
//
//  PowerButtonRow.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//

import SwiftUI

struct PowerButtonRow: View {
    let isOn: Bool
    let speed: Double
    let onToggle: () -> Void
    let onChangeSpeed: (Double) -> Void

    var body: some View {
        HStack(spacing: 14) {
            GuidedPowerButton(
                isOn: isOn,
                action: onToggle
            )

            if isOn {
                HStack(spacing: 10) {
                    Image(systemName: "fan")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 24, alignment: .center)
                        .accessibilityHidden(true)

                    Slider(
                        value: Binding(
                            get: { speed },
                            set: { onChangeSpeed(min(1, max(0, $0))) }
                        ),
                        in: 0...1
                    )
                    .accessibilityLabel("Fan speed")
                    .sliderTintGray()

                    Text("\(Int(speed * 100))%")
                        .font(.footnote.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct GuidedPowerButton: View {
    let isOn: Bool
    let action: () -> Void

    @State private var rotation: Double = 0
    @State private var ringToken = UUID()
    @State private var showRing = false
    @State private var revealTask: Task<Void, Never>? = nil

    private let shape = Capsule()
    private let buttonWidth: CGFloat = 60
    private let buttonHeight: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: "power")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: buttonWidth, height: buttonHeight)
                .background(.thickMaterial, in: shape)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .overlay {
            if showRing && !isOn {
                spinningRing
                    .id(ringToken)
                    .padding(-4)
                    .allowsHitTesting(false)
                    .onAppear {
                        startSpin()
                    }
                    .transition(.opacity)
            }
        }
        .onAppear {
            updateRingVisibility(for: isOn)
        }
        .onChange(of: isOn) { _, newValue in
            updateRingVisibility(for: newValue)
        }
        .onDisappear {
            revealTask?.cancel()
        }
        .accessibilityLabel(isOn ? "Turn device off" : "Turn device on")
    }

    private var spinningRing: some View {
        shape
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .red
                    ]),
                    center: .center,
                    angle: .degrees(rotation)
                ),
                lineWidth: 2.5
            )
            .frame(width: buttonWidth + 8, height: buttonHeight + 8)
    }

    private func updateRingVisibility(for isOn: Bool) {
        revealTask?.cancel()

        if isOn {
            showRing = false
            stopSpin()
            return
        }

        showRing = false
        stopSpin()

        revealTask = Task { @MainActor in
//            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            guard !self.isOn else { return }

            ringToken = UUID()
            withAnimation(.easeInOut(duration: 1)) {
                showRing = true
            }
        }
    }

    private func startSpin() {
        rotation = 0
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    private func stopSpin() {
        rotation = 0
    }
}
