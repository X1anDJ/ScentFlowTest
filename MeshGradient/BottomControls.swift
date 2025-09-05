import SwiftUI

struct BottomControls: View {
    // Inputs from the VM
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let focusedName: String?
    let canSelectMore: Bool
    let opacities: [String: Double]
    let onTapHue: (String) -> Void
    let onChangeOpacity: (_ name: String, _ value: Double) -> Void

    // Local UI state
    @State private var isExpanded = false
    @State private var pageIndex = 0 // 0 = Controls, 1 = Templates

    // Sample templates (replace with your own persistence later)
    @State private var templates: [ColorTemplate] = [
        ColorTemplate(
            name: "Sunset",
            included: ["Red", "Orange", "Violet"],
            opacities: ["Red": 0.9, "Orange": 0.8, "Violet": 0.7]
        ),
        ColorTemplate(
            name: "Ocean",
            included: ["Cyan", "Blue", "Green"],
            opacities: ["Cyan": 0.9, "Blue": 0.8, "Green": 0.6]
        ),
        ColorTemplate(
            name: "Mint",
            included: ["Green", "Cyan"],
            opacities: ["Green": 0.7, "Cyan": 0.6]
        )
    ]

    // MARK: - Height caps to keep the circle visible
    private var targetHeight: CGFloat {
        #if os(iOS)
        let H = UIScreen.main.bounds.height
        #else
        let H: CGFloat = 900
        #endif
        // Reasonable caps for different pages/states (fits bottom, avoids covering center)
        let collapsed = min(200, H * 0.28)
        let expanded  = min(420, H * 0.55)
        let templates = min(240, H * 0.32)
        if pageIndex == 1 { return templates }
        return isExpanded ? expanded : collapsed
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header row: tap to expand/collapse; shows pager context
            HStack(spacing: 10) {
                Image(systemName: headerIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .opacity(0.85)
                    .animation(.default, value: pageIndex)
                Text(headerTitle)
                    .font(.headline)
                    .opacity(0.95)
                    .animation(.default, value: pageIndex)
                Spacer()

                // Simple page indicator (two dots)
                HStack(spacing: 6) {
                    Circle().frame(width: 6, height: 6)
                        .opacity(pageIndex == 0 ? 0.95 : 0.25)
                    Circle().frame(width: 6, height: 6)
                        .opacity(pageIndex == 1 ? 0.95 : 0.25)
                }
                .foregroundStyle(.secondary)

                // Expand/collapse chevron (only meaningful on Controls page)
                Image(systemName: "chevron.up")
                    .rotationEffect(.degrees((isExpanded && pageIndex == 0) ? 0 : 180))
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(pageIndex == 0 ? 0.7 : 0.2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isExpanded)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard pageIndex == 0 else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            }

            // Swipe left/right between the two "cards"
            TabView(selection: $pageIndex) {
                // PAGE 0 – Controls
                ControlsPage(
                    names: names,
                    colorDict: colorDict,
                    included: included,
                    focusedName: focusedName,
                    canSelectMore: canSelectMore,
                    opacities: opacities,
                    isExpanded: $isExpanded,
                    onTapHue: onTapHue,
                    onChangeOpacity: onChangeOpacity
                )
                .tag(0)

                // PAGE 1 – Templates
                TemplatesPage(
                    names: names,
                    colorDict: colorDict,
                    templates: templates
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: pageIndex)
        }
        .padding(.vertical, (isExpanded && pageIndex == 0) ? 16 : 12)
        .padding(.horizontal, 14)
        .background(LiquidGlassBackground(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
        // Cap the CARD height so it stays a "bottom control"
        .frame(maxWidth: .infinity)
        .frame(height: targetHeight)
        // Tap anywhere on the card to expand (only on Controls page to avoid slider conflicts)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {
            guard pageIndex == 0, !isExpanded else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isExpanded = true
            }
        }
    }

    private var headerTitle: String {
        pageIndex == 0 ? "Color Controls" : "Templates"
    }
    private var headerIcon: String {
        pageIndex == 0 ? "slider.horizontal.3" : "square.grid.2x2"
    }
}

// MARK: - Controls Page

private struct ControlsPage: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let focusedName: String?
    let canSelectMore: Bool
    let opacities: [String: Double]
    @Binding var isExpanded: Bool
    let onTapHue: (String) -> Void
    let onChangeOpacity: (_ name: String, _ value: Double) -> Void

    var body: some View {
        Group {
            if isExpanded {
                // Expanded: make content scrollable so the card height can stay capped.
                ScrollView(.vertical, showsIndicators: true) {
                    ExpandedControls(
                        names: names,
                        colorDict: colorDict,
                        included: included,
                        opacities: opacities,
                        canSelectMore: canSelectMore,
                        onTapHue: onTapHue,
                        onChangeOpacity: onChangeOpacity
                    )
                    .padding(.bottom, 6)
                }
            } else {
                // Collapsed: hue picker row + single contextual slider
                VStack(spacing: 14) {
                    HueCircles(
                        names: names,
                        colorDict: colorDict,
                        included: included,
                        focusedName: focusedName,
                        canSelectMore: canSelectMore,
                        onTap: onTapHue
                    )

                    OpacityControl(
                        focusedName: focusedName,
                        isFocusedIncluded: focusedName.map { included.contains($0) } ?? false,
                        value: focusedName.flatMap { opacities[$0] } ?? 1,
                        onChange: onChangeOpacity
                    )
                }
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Expanded Controls

private struct ExpandedControls: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let opacities: [String: Double]
    let canSelectMore: Bool
    let onTapHue: (String) -> Void
    let onChangeOpacity: (String, Double) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: vertical list of colors with sliders
            VStack(alignment: .leading, spacing: 14) {
                ForEach(names, id: \.self) { name in
                    ColorRow(
                        name: name,
                        color: colorDict[name] ?? .gray,
                        isIncluded: included.contains(name),
                        value: opacities[name] ?? 1,
                        canSelectMore: canSelectMore,
                        onTapHue: onTapHue,
                        onChangeOpacity: onChangeOpacity
                    )
                }
            }
            .frame(minWidth: 240, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }
}

private struct ColorRow: View {
    let name: String
    let color: Color
    let isIncluded: Bool
    let value: Double
    let canSelectMore: Bool
    let onTapHue: (String) -> Void
    let onChangeOpacity: (String, Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    if isIncluded {
                        onTapHue(name) // remove
                    } else if canSelectMore {
                        onTapHue(name) // add
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .fill(color)
                                    .opacity(isIncluded ? 1 : 0)
                                    .padding(4)
                            )
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(name) \(isIncluded ? "added" : "not added")")

                Text(name)
                    .font(.subheadline)
                    .fontWeight(isIncluded ? .semibold : .regular)
                    .opacity(isIncluded ? 1 : 0.6)

                Spacer()

                Text(String(format: "%.0f%%", (value * 100).rounded()))
                    .font(.footnote.monospacedDigit())
                    .opacity(isIncluded ? 0.9 : 0.4)
            }

            Slider(
                value: Binding(
                    get: { value },
                    set: { onChangeOpacity(name, $0) }
                ),
                in: 0...1
            )
            .disabled(!isIncluded)
            .opacity(isIncluded ? 1 : 0.45)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Templates Page

private struct TemplatesPage: View {
    let names: [String]
    let colorDict: [String: Color]
    let templates: [ColorTemplate]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Templates")
                .font(.subheadline.weight(.semibold))
                .opacity(0.9)
                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(templates) { t in
                        VStack(spacing: 8) {
                            let palette = buildPalette(
                                canonicalOrder: names,
                                colorDict: colorDict,
                                included: t.included,
                                opacities: t.opacities
                            )

                            GradientContainerCircle(colors: palette)
                                .frame(width: 80, height: 80)

                            Text(t.name)
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
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Model + Helpers for Templates

private struct ColorTemplate: Identifiable {
    let id = UUID()
    let name: String
    let included: Set<String>
    let opacities: [String: Double]
}

/// Build a palette like the VM does:
/// - apply per-name opacity,
/// - drop ~transparent entries,
/// - ensure at least 3 stops by synthesizing when needed.
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
            let a = opacities[name] ?? 1
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

// MARK: - Liquid Glass Background

private struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            // Subtle diagonal sheen
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.14), location: 0.0),
                        .init(color: .white.opacity(0.02), location: 0.45),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            // Inner highlight
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 0.8)
                    .blendMode(.overlay)
            )
            // Soft outer shadow for "liquid glass" float
            .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 18)
    }
}

// MARK: - Preview

#Preview {
    // Lightweight harness for previewing the control
    struct Harness: View {
        @StateObject var vm = GradientWheelViewModel()
        var body: some View {
            ZStack {
                LinearGradient(colors: [.black, .gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    BottomControls(
                        names: vm.canonicalOrder,
                        colorDict: vm.colorDict,
                        included: vm.included,
                        focusedName: vm.focusedName,
                        canSelectMore: vm.canSelectMore,
                        opacities: vm.opacities,
                        onTapHue: { vm.toggle($0) },
                        onChangeOpacity: { name, v in vm.setOpacity(v, for: name) }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    return Harness()
}
