import SwiftUI

struct AddScentsView: View {
    @Binding var selectedCategory: Category?
    /// Names of scents currently selected (top `activeColors` in the parent)
    let selectedNames: [String]
    /// Called when a new scent is chosen (no-op if already at capacity handled here)
    let onSelect: (_ color: Color, _ name: String) -> Void

    // derived state
    private var selectedSet: Set<String> { Set(selectedNames) }
    private var selectedCount: Int { selectedNames.count }
    private let capacity: Int = 6

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // live selection count
                Text("\(selectedCount)/\(capacity) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                
                Spacer()
                
                Group {
                    if let cat = selectedCategory {
                        categorySubOptionsGrid(for: cat)
                            .navigationTitle(cat.displayName)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("All Categories") {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.95)) {
                                            selectedCategory = nil
                                        }
                                    }
                                }
                            }
                    } else {
                        categoriesGrid()
                            .navigationTitle("All Categories")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
            }
        }
    }
}

// MARK: - All Categories (grid)

private extension AddScentsView {
    func categoriesGrid() -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(Category.allCases, id: \.self) { cat in
                // how many selected from this category
                let countInCat = cat.optionsEN.reduce(into: 0) { if selectedSet.contains($1) { $0 += 1 } }
                VStack(spacing: 8) {
                    CategorySwatchButton(
                        tint: cat.color,
                        countSelectedInCategory: countInCat
                    ) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            selectedCategory = cat
                        }
                    }
                    Text(countInCat > 0 ? "\(cat.label) x\(countInCat)" : cat.label)
                        .font(.caption)
                        .foregroundStyle(countInCat > 0 ? .primary : .secondary)
                }
            }
        }
    }
}

// MARK: - Suboptions (scents within a category)

private extension AddScentsView {
    func categorySubOptionsGrid(for cat: Category) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(cat.optionsEN, id: \.self) { name in
                let isSelected = selectedSet.contains(name)
                let isFull = !isSelected && selectedCount >= capacity

                VStack(spacing: 8) {
                    ScentSwatchButton(
                        tint: cat.color,
                        isSelected: isSelected,
                        disabled: isFull
                    ) {
                        guard !isSelected, !isFull else { return }
                        onSelect(cat.color, name)      // parent adds
                        // go back to All Categories (keep sheet open)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.95)) {
                            selectedCategory = nil
                        }
                    }
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}

// MARK: - Button building blocks

/// Category tile: always filled; if any scent selected in that category -> full opacity + colored shadow.
private struct CategorySwatchButton: View {
    var tint: Color
    var countSelectedInCategory: Int
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(tint.opacity(countSelectedInCategory > 0 ? 1.0 : 0.6))
                .modifier(GlassIfAvailable())
                .frame(width: 44, height: 44)
                .shadow(
                    color: countSelectedInCategory > 0 ? tint.opacity(0.6) : .clear,
                    radius: countSelectedInCategory > 0 ? 10 : 0,
                    x: 0, y: countSelectedInCategory > 0 ? 4 : 0
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(Text(countSelectedInCategory > 0 ? "Selected category" : "Category"))
    }
}

/// Scent tile (suboptions): ring when not selected; filled when selected; never shows a shadow.
private struct ScentSwatchButton: View {
    var tint: Color
    var isSelected: Bool
    var disabled: Bool
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(tint)
                        .modifier(GlassIfAvailable())
                } else {
                    Circle()
                        .strokeBorder(tint, lineWidth: 3)
                        .background(Circle().fill(Color.clear))
                }
            }
            .frame(width: 44, height: 44)
            .opacity(disabled ? 0.5 : 1.0)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(Text(isSelected ? "Selected scent" : "Scent"))
    }
}

// MARK: - Glass effect helper

private struct GlassIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect()
        } else {
            content.overlay(
                Circle().fill(.ultraThinMaterial)
            )
        }
    }
}
