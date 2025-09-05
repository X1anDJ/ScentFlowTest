import SwiftUI

struct OpacityControl: View {
    let focusedName: String?
    let isFocusedIncluded: Bool
    /// Effective stored value in the VM (0...1), capped by `AppConfig.maxIntensity` via UI mapping.
    let value: Double
    let onChange: (_ name: String, _ value: Double) -> Void

    /// Slider shows 0...100%, while the applied value is `slider * maxIntensity`.
    /// displayed = effective / maxIntensity, applied = displayed * maxIntensity
    private var displayedSliderValue: Double {
        guard isFocusedIncluded else { return 0 }
        let maxI = max(0.0001, AppConfig.maxIntensity)
        return min(1.0, value / maxI)
    }

    var body: some View {
        Group {
            if let name = focusedName, isFocusedIncluded {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Intensity")
                            .font(.headline)
                        Spacer()
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill").opacity(0.6)

                        Slider(
                            value: Binding(
                                get: { displayedSliderValue },
                                set: { newDisplayed in
                                    let clamped = max(0, min(1, newDisplayed))
                                    let applied = clamped * AppConfig.maxIntensity
                                    onChange(name, applied)
                                }
                            ),
                            in: 0...1
                        )

                        // Show the slider's percentage (0–100), not the applied 0…maxIntensity.
                        Text(String(format: "%.0f%%", (displayedSliderValue * 100).rounded()))
                            .font(.footnote.monospacedDigit())
                            .frame(width: 44, alignment: .trailing)
                            .opacity(0.9)
                    }
                }
            } else {
                // Blank when nothing is selected (no hint text)
                EmptyView()
            }
        }
    }
}
