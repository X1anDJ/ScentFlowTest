import SwiftUI

struct OpacityControl: View {
    let focused: Scent?
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let focused {
                HStack {
                    Text("\(focused.name) Scent")
                        .font(.subheadline).opacity(0.8)
                    Spacer()
                    Text("\(Int((value / AppConfig.maxIntensity) * 100))%")
                        .font(.footnote).opacity(0.6)
                }
                Slider(value: $value, in: AppConfig.minIntensity...AppConfig.maxIntensity)
                    .sliderTintGray()
            } else {
                Text("Select a scent to adjust intensity")
                    .font(.headline).opacity(0.6)
            }
        }
    }
}
