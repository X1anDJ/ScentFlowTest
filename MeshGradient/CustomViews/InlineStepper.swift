import SwiftUI

struct InlineStepperStyle {
    // Layout
    var controlHeight: CGFloat = 30
    var spacing: CGFloat = 0
    var contentCorner: CGFloat = 15 // capsule radius (half of height is fine)

    // Buttons
    var minusButtonSize: CGSize = .init(width: 30, height: 30)
    var plusButtonSize:  CGSize = .init(width: 30, height: 30)

    // Value label
    var valueBoxSize: CGSize = .init(width: 44, height: 30)
    var valueFont: Font = .title3.weight(.semibold)
    var valueMinScale: CGFloat = 0.8
    var animate: Animation = .snappy

    // Dividers
    var dividerHeight: CGFloat = 22
    var dividerOpacity: CGFloat = 0.4

    // Stroke & background
    var strokeWidth: CGFloat = 1
    var backgroundMaterial: Material = .thinMaterial

    // Shadow
    var shadowColor: Color = .black.opacity(0.06)
    var shadowRadius: CGFloat = 4
    var shadowY: CGFloat = 0
}

struct InlineStepper: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String
//    @Environment(\.colorScheme) private var colorScheme
    
    // New: style configuration with sensible defaults
    var style: InlineStepperStyle = .init()

    var body: some View {
//        let shadowColor = (colorScheme == .dark ? Theme.Shadow.wheelDark : Theme.Shadow.wheelLight)
        
        HStack(spacing: style.spacing) {
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .foregroundStyle(.primary)
                    .frame(width: style.minusButtonSize.width, height: style.minusButtonSize.height) // hit target
                    .contentShape(Rectangle())
                    .accessibilityLabel("Decrease")
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: style.dividerHeight)
                .opacity(style.dividerOpacity)

            // Value in the middle, single line, big and readable
            Text(format(value))
                .font(.subheadline)
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(style.valueMinScale)
                .frame(width: style.valueBoxSize.width, height: style.valueBoxSize.height) // fixed width to keep layout stable
                .contentTransition(.numericText()) // iOS 17+
                .animation(style.animate, value: value)

            Divider()
                .frame(height: style.dividerHeight)
                .opacity(style.dividerOpacity)

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(.primary)
                    .frame(width: style.plusButtonSize.width, height: style.plusButtonSize.height)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Increase")
            }
            .buttonStyle(.plain)
        }
        .frame(height: style.controlHeight)
        .background(style.backgroundMaterial, in: Capsule())
//        .overlay(
//            Capsule().strokeBorder(style.strokeColor, lineWidth: style.strokeWidth)
//        )
        // Subtle shadow for depth (like controls in sheets)
        //.shadow(color: shadowColor.opacity(0.5), radius: style.shadowRadius, y: style.shadowY)
        // Haptics (iOS 17): bumps when value changes
//        .sensoryFeedback(.increase, trigger: value > oldValue)
//        .sensoryFeedback(.decrease, trigger: value < oldValue)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Value")
        .accessibilityValue(format(value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(range.upperBound, value + step)
            case .decrement: value = max(range.lowerBound, value - step)
            default: break
            }
        }
        // Keep `oldValue` in sync so haptic triggers work correctly
        .background(_onChange)
    }

    // Track previous value for haptics triggers
    @State private var oldValue: Double = .zero
    private var _onChange: some View {
        EmptyView().onChange(of: value) { old, _ in
            oldValue = old
        }
    }
}
