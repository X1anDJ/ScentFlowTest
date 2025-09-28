// RadialCategoryRing.swift
import SwiftUI

/// Evenly distributes category swatches around a circle (44×44).
/// Behaviors:
/// - On sheet present: all categories fan out from 12 o'clock along the arc (0.5s).
/// - Tap a category: it slides to the **center** (radius -> 0) and scales to 1.2× (0.5s).
///   Its suboptions (up to 3) animate along the ring into neighboring slots (i-1, i, i+1),
///   each using the **shortest arc** (so first/last don’t wrap the long way).
///   Other categories fade out during focus; they fade back in on revert.
/// - Suboptions are **rings** when unselected and **solid** when selected. Tapping toggles:
///   - if not selected → select (solid) and call `onSelect`
///   - if selected     → deselect (ring)  and call `onDeselect`
struct RadialCategoryRing: View {
    let items: [Category]
    /// Names currently selected globally (from parent). Used to show persisted selections.
    let selectedSet: Set<String>
    /// Callbacks to keep parent state authoritative (prevents duplicates).
    let onSelect: (Category, String) -> Void
    let onDeselect: (String) -> Void
    var runInitialFanOut: Bool = true

    // Layout
    private let ringPadding: CGFloat = 16
    private let labelSpacing: CGFloat = 8
    private let startAngleDeg: Double = -90   // 12 o'clock
    private let swatchSize: CGFloat = 44
    private let focusedScale: CGFloat = 1.2

    // NEW: one source of truth for label styling
    private let labelFont: Font = .system(size: 12) // fixed size, no scaling

    // State
    private enum Mode: Equatable { case all, focus(index: Int) }
    @State private var mode: Mode = .all

    // Animations
    @State private var appearProgress: Double = 0  // 0 → fan from top, 1 → final ring
    @State private var focusProgress: Double = 0   // 0 → all, 1 → focused layout
    @State private var subProgress: Double = 0     // 0 → subs overlap at tapped slot, 1 → neighbor slots

    // While focused, remember which suboption is “actively selected” (starts from parent's selectedSet).
    @State private var focusedSelectedName: String? = nil

    var body: some View {
        GeometryReader { geo in
            let minSide = min(geo.size.width, geo.size.height)
            let r = max(0, (minSide / 2) - ringPadding - (swatchSize / 2))
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let step = 360.0 / Double(max(items.count, 1))

            ZStack {
                switch mode {
                case .all:
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, cat in
                        categorySwatchCentered(
                            cat: cat,
                            countInCat: countSelected(in: cat),
                            onTap: { focus(on: idx) } // Button handles tap
                        )
                        .modifier(ArcAlongCircle(
                            center: center,
                            radius: r,
                            startAngleDegrees: startAngleDeg,
                            endAngleDegrees: startAngleDeg + Double(idx) * step,
                            t: appearProgress
                        ))
                    }

                case .focus(let s):
                    let focusedAngle = startAngleDeg + Double(s) * step

                    // Selected category -> center (radius 0) with scale
                    categorySwatchCentered(
                        cat: items[s],
                        countInCat: countSelected(in: items[s]),
                        showLabel: false,
                        onTap: {} // ignore taps while focused
                    )
                    .modifier(RadialSlide(
                        center: center,
                        angleDegrees: focusedAngle,
                        startRadius: r,
                        endRadius: 0,                     // to center
                        t: focusProgress
                    ))
                    .scaleEffect(1 + (focusedScale - 1) * focusProgress)
                    .zIndex(2)

                    // Suboptions occupy [s-1, s, s+1] (wrap), ring/solid based on selection
                    let subs = Array(items[s].optionsEN.prefix(3))
                    let targetSlots = contiguousSlotsCentered(at: s, count: subs.count, total: items.count)
                    let arcStart = focusedAngle  // start overlapped at tapped slot

                    ForEach(Array(subs.enumerated()), id: \.offset) { j, name in
                        let targetIdx = targetSlots[j]
                        let endAngle = startAngleDeg + Double(targetIdx) * step
                        let isPersisted = selectedSet.contains(name)
                        // Focused state should show prior persisted selection when you open this category
                        let isSelected = (focusedSelectedName ?? persistedName(for: items[s])) == name || isPersisted

                        suboptionSwatchCentered(
                            tint: items[s].color,
                            name: name,
                            isSelected: isSelected
                        )
                        .modifier(ArcAlongCircle(
                            center: center,
                            radius: r,                    // suboptions live on the ring
                            startAngleDegrees: arcStart,
                            endAngleDegrees: endAngle,
                            t: subProgress,
                            useShortestArc: true
                        ))
                        .onTapGesture {
                            toggleSuboption(name: name, category: items[s])
                        }
                        .zIndex(1)
                    }

                    // Other categories fade out during focus (non-interactive)
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, cat in
                        if idx != s && !targetSlots.contains(idx) {
                            categorySwatchCentered(
                                cat: cat,
                                countInCat: countSelected(in: cat),
                                showLabel: false,
                                onTap: {}
                            )
                            .modifier(ArcAlongCircle(
                                center: center,
                                radius: r,
                                startAngleDegrees: startAngleDeg,
                                endAngleDegrees: startAngleDeg + Double(idx) * step,
                                t: 1
                            ))
                            .opacity(1 - focusProgress) // fade out with focus
                            .allowsHitTesting(false)
                        }
                    }
                }
            }
            .onAppear {
                // Initial fan-out from 12 o'clock
                appearProgress = 0
                if runInitialFanOut {
                    withAnimation(.easeOut(duration: 0.5)) { appearProgress = 1 }
                } else {
                    appearProgress = 1
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Actions

    private func focus(on index: Int) {
        mode = .focus(index: index)
        // Seed focusedSelectedName from parent's persisted selection for this category
        focusedSelectedName = persistedName(for: items[index])
        focusProgress = 0
        subProgress = 0
        withAnimation(.easeOut(duration: 0.5)) {
            focusProgress = 1
            subProgress = 1
        }
    }

    private func revertToAll() {
        withAnimation(.easeOut(duration: 0.5)) {
            // others fade back in as focusProgress goes to 0
            focusProgress = 0
            subProgress = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mode = .all
            focusedSelectedName = nil
        }
    }

    /// Toggle logic:
    /// - If tapping the already-selected name → deselect (ring), call `onDeselect`.
    /// - If tapping a different name → ensure at most one per category:
    ///     deselect previous (if any), then select new and call `onSelect`.
    private func toggleSuboption(name: String, category: Category) {
        let persisted = persistedName(for: category)
        if focusedSelectedName == name || persisted == name {
            // Deselect
            focusedSelectedName = nil
            onDeselect(name)
            // stay in focus; don't revert automatically
            return
        }
        // Switching to a different suboption:
        if let prev = (focusedSelectedName ?? persisted), prev != name {
            onDeselect(prev)
        }
        focusedSelectedName = name
        // Prevent duplicates: only call onSelect if not already in parent's set
        if !selectedSet.contains(name) {
            onSelect(category, name)
        }
        // After picking a (new) suboption, revert to full ring
        revertToAll()
    }

    // MARK: - Helpers

    private func countSelected(in cat: Category) -> Int {
        cat.optionsEN.reduce(into: 0) { if selectedSet.contains($1) { $0 += 1 } }
    }

    /// The parent's persisted selection for this category, if any.
    private func persistedName(for cat: Category) -> String? {
        cat.optionsEN.first(where: { selectedSet.contains($0) })
    }

    /// Contiguous indices centered on `centerIndex` (wrap-around).
    private func contiguousSlotsCentered(at centerIndex: Int, count: Int, total: Int) -> [Int] {
        guard total > 0 && count > 0 else { return [] }
        let left = (count - 1) / 2
        let start = centerIndex - left
        return (0..<count).map { off in
            let i = (start + off) % total
            return i < 0 ? i + total : i
        }
    }

    // MARK: - Centered nodes (labels don’t affect positioning)

    private func categorySwatchCentered(
        cat: Category,
        countInCat: Int,
        showLabel: Bool = true,
        onTap: @escaping () -> Void
    ) -> some View {
        let labelText = countInCat > 0 ? "\(cat.label) x \(countInCat)" : cat.label

        return ZStack {
            CategorySwatchButton(
                tint: cat.color,
                countSelectedInCategory: countInCat,
                action: onTap
            )
            .frame(width: swatchSize, height: swatchSize)
            .contentShape(Circle())
        }
        .overlay(alignment: .center) {
            if showLabel {
                Text(labelText)
                    .ringLabel(labelFont)                 // unified style
                    .frame(width: 150)
                    .offset(y: swatchSize/2 + labelSpacing)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: swatchSize, height: swatchSize) // positioned by swatch center
    }

    private func suboptionSwatchCentered(tint: Color, name: String, isSelected: Bool) -> some View {
        ZStack {
            Circle().fill(Color.clear) // full circular tap target
            if isSelected {
                Circle().fill(tint).modifier(GlassIfAvailable())
            } else {
                Circle().strokeBorder(tint, lineWidth: 3)
            }
        }
        .frame(width: swatchSize * 0.8, height: swatchSize * 0.8)
        .contentShape(Circle())
        .overlay(alignment: .center) {
            Text(name)
                .ringLabel(labelFont)                     // unified style
                .frame(width: 120)
                .offset(y: (swatchSize * 0.8)/2 + 6)
                .allowsHitTesting(false)
        }
        .frame(width: swatchSize * 0.8, height: swatchSize * 0.8)
    }
}

// MARK: - Animatable Modifiers

/// Animate along a circular arc, using the **shortest angular path** to avoid long wrap.
private struct ArcAlongCircle: AnimatableModifier {
    var center: CGPoint
    var radius: CGFloat
    var startAngleDegrees: Double
    var endAngleDegrees: Double
    var t: Double
    var useShortestArc: Bool = false

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    func body(content: Content) -> some View {
        let delta = useShortestArc
            ? shortestAngleDeltaDegrees(from: startAngleDegrees, to: endAngleDegrees)
            : (endAngleDegrees - startAngleDegrees)
        let angleDeg = startAngleDegrees + delta * t
        let rad = angleDeg * .pi / 180
        let x = center.x + cos(rad) * radius
        let y = center.y + sin(rad) * radius
        return content.position(x: x, y: y)
    }

    private func shortestAngleDeltaDegrees(from a: Double, to b: Double) -> Double {
        var d = fmod((b - a), 360)
        if d <= -180 { d += 360 }
        if d >  180 { d -= 360 }
        return d
    }
}

/// Animate radially along a fixed angle (toward/away from center).
private struct RadialSlide: AnimatableModifier {
    var center: CGPoint
    var angleDegrees: Double
    var startRadius: CGFloat
    var endRadius: CGFloat
    var t: Double

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    func body(content: Content) -> some View {
        let rad = angleDegrees * .pi / 180
        let radius = startRadius + (endRadius - startRadius) * CGFloat(t)
        let x = center.x + cos(rad) * radius
        let y = center.y + sin(rad) * radius
        return content.position(x: x, y: y)
    }
}

// MARK: - Label style (centralized)
private struct RingLabelStyle: ViewModifier {
    let font: Font
    func body(content: Content) -> some View {
        content
            .font(font)                 // fixed font size
            .foregroundStyle(.primary)  // uniform color
            .lineLimit(1)               // no multi-line
            .truncationMode(.tail)      // clip, don't shrink
            .minimumScaleFactor(1)      // disable text-fit scaling
            .dynamicTypeSize(.medium)   // lock out Dynamic Type scaling for this view
    }
}

private extension View {
    func ringLabel(_ font: Font) -> some View { modifier(RingLabelStyle(font: font)) }
}
