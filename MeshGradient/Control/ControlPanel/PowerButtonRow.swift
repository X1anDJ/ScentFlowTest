import SwiftUI

struct PowerButtonRow: View {
    let isOn: Bool
    let speed: Double
    let onToggle: () -> Void
    let onChangeSpeed: (Double) -> Void

    let showsTemplateTransport: Bool
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    init(
        isOn: Bool,
        speed: Double,
        onToggle: @escaping () -> Void,
        onChangeSpeed: @escaping (Double) -> Void,
        showsTemplateTransport: Bool = false,
        canGoPrevious: Bool = false,
        canGoNext: Bool = false,
        onPrevious: @escaping () -> Void = {},
        onNext: @escaping () -> Void = {}
    ) {
        self.isOn = isOn
        self.speed = speed
        self.onToggle = onToggle
        self.onChangeSpeed = onChangeSpeed
        self.showsTemplateTransport = showsTemplateTransport
        self.canGoPrevious = canGoPrevious
        self.canGoNext = canGoNext
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    var body: some View {
        HStack(spacing: 16) {
            if showsTemplateTransport {
                TransportButton(
                    systemName: "backward.fill",
                    isEnabled: canGoPrevious,
                    action: onPrevious
                )
            }

            GuidedPowerButton(
                isOn: isOn,
                action: onToggle
            )

            if showsTemplateTransport {
                TransportButton(
                    systemName: "forward.fill",
                    isEnabled: canGoNext,
                    action: onNext
                )
            }

//            if isOn {
//                HStack(spacing: 10) {
//                    Slider(
//                        value: Binding(
//                            get: { speed },
//                            set: { onChangeSpeed(min(1, max(0, $0))) }
//                        ),
//                        in: 0...1
//                    )
//                    .accessibilityLabel("Fan speed")
//                    .sliderTintGray()
//
//                    Text("\(Int(speed * 100))%")
//                        .font(.footnote.monospacedDigit())
//                        .frame(width: 44, alignment: .trailing)
//                        .foregroundStyle(.secondary)
//                }
//                .transition(.move(edge: .trailing).combined(with: .opacity))
//            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct TransportButton: View {
    let systemName: String
    let isEnabled: Bool
    let action: () -> Void

    private let shape = Capsule()
    private let width: CGFloat = 44
    private let height: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isEnabled ? .primary : .secondary)
                .frame(width: width, height: height)
                .background(.thickMaterial, in: shape)
                .contentShape(shape)
                .opacity(isEnabled ? 1.0 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
    private let buttonHeight: CGFloat = 60

    var body: some View {
        Button(action: action) {
            Group {
                if isOn {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24, weight: .semibold))
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .offset(x: 1)
                }
            }
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
        .accessibilityValue(isOn ? "On" : "Off")
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
