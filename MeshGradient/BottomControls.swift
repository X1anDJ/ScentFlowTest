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
    let onApplyTemplate: (_ included: Set<String>, _ opacities: [String: Double]) -> Void

    // Local UI state
    @State private var isExpanded = false
    @State private var pageIndex = 0 // 0 = Controls, 1 = Templates
    @State private var activeTemplateName: String? = nil // nil -> "Unsaved Scent"

    // Templates live here; you can move this into the VM later if you want persistence.
    @State private var templates: [ColorTemplate] = []

    // Save flow
    @State private var showSaveSheet = false
    @State private var newTemplateName = ""

    // MARK: - Height caps to keep the circle visible
    private var targetHeight: CGFloat {
        #if os(iOS)
        let H = UIScreen.main.bounds.height
        #else
        let H: CGFloat = 900
        #endif
        let collapsed = min(200, H * 0.28)
        let expanded  = min(420, H * 0.55)
        let templatesH = min(200, H * 0.28)
        if pageIndex == 1 { return templatesH }
        return isExpanded ? expanded : collapsed
    }

    // Clear template binding whenever the user tweaks anything.
    private func handleTapHue(_ name: String) {
        activeTemplateName = nil
        onTapHue(name)
    }
    private func handleChangeOpacity(_ name: String, _ value: Double) {
        activeTemplateName = nil
        onChangeOpacity(name, value)
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

                // Save button (controls page only)
                if pageIndex == 0 {
                    Button {
                        showSaveSheet = true
                    } label: {
                        Label("Save", systemImage: "tray.and.arrow.down")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .opacity(included.isEmpty ? 0.25 : 0.9)
                    .disabled(included.isEmpty)
                }

                // Page indicator (two dots)
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
                    onTapHue: handleTapHue,
                    onChangeOpacity: handleChangeOpacity
                )
                .tag(0)

                // PAGE 1 – Templates
                TemplatesGallery(
                    names: names,
                    colorDict: colorDict,
                    templates: templates,
                    onTapTemplate: { t in
                        // Apply + reflect the active template name
                        activeTemplateName = t.name
                        onApplyTemplate(t.included, t.opacities)
                        // Snap to Controls page after applying
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            pageIndex = 0
                            isExpanded = false
                        }
                    },
                    onDeleteTemplate: { t in
                        templates.removeAll { $0.id == t.id }
                        if activeTemplateName == t.name { activeTemplateName = nil }
                    }
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
        .frame(maxWidth: .infinity)
        .frame(height: targetHeight)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {
            guard pageIndex == 0, !isExpanded else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isExpanded = true
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveTemplateSheet(
                name: $newTemplateName,
                suggestedName: suggestedTemplateName(),
                onCancel: {
                    newTemplateName = ""
                    showSaveSheet = false
                },
                onSave: { name in
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalName = trimmed.isEmpty ? suggestedTemplateName() : trimmed
                    let filteredOpacities = names.reduce(into: [String: Double]()) { acc, key in
                        if included.contains(key) { acc[key] = opacities[key] ?? 1 }
                    }
                    let newT = ColorTemplate(name: finalName, included: included, opacities: filteredOpacities)
                    templates.append(newT)
                    activeTemplateName = finalName // saved -> no longer "Unsaved Scent"
                    newTemplateName = ""
                    showSaveSheet = false
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        pageIndex = 1
                    }
                }
            )
            .presentationDetents([.height(220)])
            .presentationCornerRadius(20)
        }
    }

    private var headerTitle: String {
        if pageIndex == 1 { return "Templates" }
        return activeTemplateName ?? "Unsaved Scent"
    }
    private var headerIcon: String {
        pageIndex == 0 ? "slider.horizontal.3" : "square.grid.2x2"
    }
    private func suggestedTemplateName() -> String {
        let count = templates.count + 1
        return "Template \(count)"
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
                VStack(spacing: 14) {
                    HueCircles(
                        names: names,
                        colorDict: colorDict,
                        included: included,
                        focusedName: focusedName,
                        canSelectMore: canSelectMore,
                        onTap: onTapHue
                    )

                    // Collapsed, per-focused control – blank when no focused+included
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
    /// Effective stored value (0...1). UI maps it to a 0–100 slider with cap `AppConfig.maxIntensity`.
    let value: Double
    let canSelectMore: Bool
    let onTapHue: (String) -> Void
    let onChangeOpacity: (String, Double) -> Void

    private var displayedSliderValue: Double {
        isIncluded ? min(1.0, value / max(0.0001, AppConfig.maxIntensity)) : 0
    }
    private var displayedPercentText: String {
        String(format: "%.0f%%", (displayedSliderValue * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    if isIncluded {
                        onTapHue(name) // remove only if focused per VM logic
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

                // Show slider's percent, not the applied effective fraction
                Text(displayedPercentText)
                    .font(.footnote.monospacedDigit())
                    .opacity(isIncluded ? 0.9 : 0.4)
            }

            Slider(
                value: Binding(
                    get: { displayedSliderValue },
                    set: { newDisplayed in
                        let clamped = max(0, min(1, newDisplayed))
                        let applied = clamped * AppConfig.maxIntensity
                        onChangeOpacity(name, applied)
                    }
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

// MARK: - Save Sheet

private struct SaveTemplateSheet: View {
    @Binding var name: String
    let suggestedName: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule().frame(width: 40, height: 5).opacity(0.25)
            Text("Save Template")
                .font(.headline)
                .opacity(0.95)

            TextField(suggestedName, text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                Button("Save") { onSave(name) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
    }
}

// MARK: - Liquid Glass Background

private struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 0.8)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 18)
    }
}
