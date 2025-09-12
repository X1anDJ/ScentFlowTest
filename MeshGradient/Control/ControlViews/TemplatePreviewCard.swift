import SwiftUI

/// Small visual card that previews a saved template using your wheel renderer.
/// Now uses a **static mesh** (no animation) so gallery items don't animate.
struct TemplatePreviewCard: View {
    let template: ColorTemplate
    let names: [String]
    let colorDict: [String: Color]

    var body: some View {
        let palette = buildPalette(
            canonicalOrder: names,
            colorDict: colorDict,
            included: template.included,
            opacities: template.opacities
        )

        return VStack(spacing: 8) {
            // ⬇️ Static preview (animate: false)
            GradientContainerCircle(colors: palette, animate: false)
                .frame(width: 80, height: 80)

            Text(template.name)
                .font(.footnote)
                .lineLimit(1)
                .frame(width: 90)
                .multilineTextAlignment(.center)
                .opacity(0.9)
        }
        .padding(10)
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
    }
}
