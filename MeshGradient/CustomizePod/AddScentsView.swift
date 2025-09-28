// AddScentsView.swift
import SwiftUI

struct AddScentsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Category?
    /// Names of scents currently selected (top `activeColors` in the parent)
    let selectedNames: [String]
    /// Called when a new scent is chosen (no-op if already at capacity handled here)
    let onSelect: (_ color: Color, _ name: String) -> Void
    let onDeselect: (_ name: String) -> Void
    
    // derived state
    private var selectedSet: Set<String> { Set(selectedNames) }
    private var selectedCount: Int { selectedNames.count }
    private let capacity: Int = 6
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // live selection count
                Text("\(selectedCount) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

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
                        
                        Spacer()
                        
                    } else {
                        // Use the radial ring instead of a grid
                        categoriesRing()
                            .frame(height: 250)
                            .navigationTitle("All Categories")
                            .navigationBarTitleDisplayMode(.inline)
                        
                        Spacer()
                        
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Text("Save")
                                    .font(.headline.bold())
                            }
                            .buttonStyle(.glass)     // matches your app’s style
                            .controlSize(.large)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 16)
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

// MARK: - Radial categories bridge

// AddScentsView.swift (snippet)
private extension AddScentsView {
    func categoriesRing() -> some View {
        RadialCategoryRing(
            items: Array(Category.allCases),
            selectedSet: selectedSet,
            onSelect: { cat, name in
                onSelect(cat.color, name)
            },
            onDeselect: { name in
                onDeselect(name)
            }
        )
        // .frame(height: 250)  // keep if you're constraining height here
    }
}


struct CategorySwatchButton: View {
    var tint: Color
    var countSelectedInCategory: Int
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(tint.opacity(countSelectedInCategory > 0 ? 1.0 : 0.5))
                .modifier(GlassIfAvailable())
                .frame(width: 44, height: 44)
                .shadow(
                    color: countSelectedInCategory > 0 ? tint.opacity(0.8) : .clear,
                    radius: countSelectedInCategory > 0 ? 10 : 0
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
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


// MARK: - Button building blocks used in this file

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
                // Invisible fill so the whole circle is a hit target
                Circle().fill(Color.clear)

                if isSelected {
                    Circle()
                        .fill(tint)
                        .modifier(GlassIfAvailable())
                } else {
                    Circle()
                        .strokeBorder(tint, lineWidth: 3)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())            // full circle is tappable (not just the ring)
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

// MARK: - Glass effect helper (made internal so other files can use it)
struct GlassIfAvailable: ViewModifier {
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
