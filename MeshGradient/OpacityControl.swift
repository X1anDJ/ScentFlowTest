import SwiftUI

struct OpacityControl: View {
    let focusedName: String?
    let isFocusedIncluded: Bool
    let value: Double
    let onChange: (_ name: String, _ value: Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Opacity")
                    .font(.headline)
                Spacer()
                if let name = focusedName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let name = focusedName, isFocusedIncluded {
                HStack(spacing: 12) {
                    Image(systemName: "drop.fill").opacity(0.6)
                    Slider(value: Binding(
                        get: { value },
                        set: { onChange(name, $0) }
                    ), in: 0...1)
                    Text("\(Int(value * 100))%")
                        .font(.footnote.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
            } else {
                Text("Tap a color to add it, then adjust its opacity here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )
            }
        }
    }
}
