import SwiftUI

// Public so other files can use it.
struct ColorTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let included: Set<String>
    let opacities: [String: Double]
}

struct TemplatesGallery: View {
    let names: [String]
    let colorDict: [String: Color]
    let templates: [ColorTemplate]
    let onTapTemplate: (ColorTemplate) -> Void
    let onDeleteTemplate: (ColorTemplate) -> Void

    @State private var toDelete: ColorTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
//            Text("Saved Templates")
//                .font(.subheadline.weight(.semibold))
//                .opacity(0.9)
//                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(templates) { t in
                        // Tapping applies, long-pressing asks to delete
                        Button {
                            onTapTemplate(t)
                        } label: {
                            TemplateCard(template: t, names: names, colorDict: colorDict)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    toDelete = t
                                }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        // Delete confirmation dialog
        .confirmationDialog(
            "Delete this template?",
            isPresented: Binding(
                get: { toDelete != nil },
                set: { if !$0 { toDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let t = toDelete {
                Button("Delete \"\(t.name)\"", role: .destructive) {
                    onDeleteTemplate(t)
                    toDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                toDelete = nil
            }
        } message: {
            if let t = toDelete {
                Text("This will remove \"\(t.name)\" permanently.")
            }
        }
    }
}

private struct TemplateCard: View {
    let template: ColorTemplate
    let names: [String]
    let colorDict: [String: Color]

    var body: some View {
        VStack(spacing: 8) {
            let palette = buildPalette(
                canonicalOrder: names,
                colorDict: colorDict,
                included: template.included,
                opacities: template.opacities
            )

            GradientContainerCircle(colors: palette)
                .frame(width: 80, height: 80)

            Text(template.name)
                .font(.footnote)
                .lineLimit(1)
                .frame(width: 90)
                .multilineTextAlignment(.center)
                .opacity(0.9)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Palette helper (templating mirrors VM behavior and global cap)

private func buildPalette(
    canonicalOrder: [String],
    colorDict: [String: Color],
    included: Set<String>,
    opacities: [String: Double]
) -> [Color] {

    let entries: [(Color, Double)] = canonicalOrder
        .filter { included.contains($0) }
        .compactMap { name in
            guard let base = colorDict[name] else { return nil }
            let raw = opacities[name] ?? AppConfig.maxIntensity
            let a = min(AppConfig.maxIntensity, max(0, raw)) // enforce cap in previews too
            return a > 0.01 ? (base, a) : nil
        }

    func withAlpha(_ c: Color, _ a: Double) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &oldA) {
            return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: a)
        }
        return c.opacity(a)
        #elseif canImport(AppKit)
        let ns = NSColor(c)
        guard let s = ns.usingColorSpace(.sRGB) else { return c.opacity(a) }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, oldA: CGFloat = 0
        s.getRed(&r, green: &g, blue: &b, alpha: &oldA)
        return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: a)
        #else
        return c.opacity(a)
        #endif
    }

    switch entries.count {
    case 0:
        return []
    case 1:
        let (base, a) = entries[0]
        return [withAlpha(base, a), withAlpha(base, a/2), withAlpha(base, a/4)]
    case 2:
        var out = entries.map { withAlpha($0.0, $0.1) }
        out.append(withAlpha(entries[0].0, entries[0].1 / 2))
        return out
    default:
        return entries.map { withAlpha($0.0, $0.1) }
    }
}
