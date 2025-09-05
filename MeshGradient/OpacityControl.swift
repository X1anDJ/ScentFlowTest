import SwiftUI

struct OpacityControl: View {
    let focusedName: String?
    let isFocusedIncluded: Bool
    /// Effective stored value in the VM (0...AppConfig.maxIntensity).
    let value: Double
    let onChange: (_ name: String, _ value: Double) -> Void

    /// Slider shows 0...100%, while the applied value is `slider * maxIntensity`.
    private var displayedSliderValue: Double {
        guard isFocusedIncluded else { return 0 }
        let maxI = max(0.0001, AppConfig.maxIntensity)
        return min(1.0, value / maxI)
    }

    var body: some View {
        Group {
            if let name = focusedName, isFocusedIncluded {
                VStack(alignment: .leading, spacing: 10) {
                    // Title row — now "<Color> Scent" (no separate color label)
                    HStack {
                        Text("\(name) Scent")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        // Show the slider's percentage (0–100), not the applied 0…maxIntensity.
                        Text(String(format: "%.0f%%", (displayedSliderValue * 100).rounded()))
                            .font(.footnote.monospacedDigit())
                            .frame(width: 44, alignment: .trailing)
                            .opacity(0.9)
                    }

                    // Slider (0...1 displayed), writes back scaled by maxIntensity
                    Slider(
                        value: Binding(
                            get: { displayedSliderValue },
                            set: { newDisplayed in
                                let applied = newDisplayed * AppConfig.maxIntensity
                                onChange(name, applied)
                            }
                        ),
                        in: 0...1
                    )
                }
            } else {
                // Blank when nothing is selected (no hint text)
                EmptyView()
            }
        }
    }
}
