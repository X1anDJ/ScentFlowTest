import SwiftUI

/// A single horizontal row of scent color circles, equally distributed across the width.
/// - Added scents: solid filled disk
/// - Not added: a ring (stroke only)
/// - Each chip sits on a ZStack with a glass-effect circular backdrop (iOS 26+).
/// - First chip remains visually leading (chips are left-aligned *within* their equal segments).
struct HueCircles: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let focusedName: String?
    let canSelectMore: Bool
    let onTap: (String) -> Void

    // Visual constants
    private let diameter: CGFloat = 28
    private let ringWidth: CGFloat = 3
    private let focusScale: CGFloat = 1.08
    private let segmentPadding: CGFloat = 4  // left padding within each equal segment

    var body: some View {
        HStack(spacing: 0) {
            ForEach(names, id: \.self) { name in
                HStack(spacing: 0) {
                    chip(for: name)
                        .frame(width: diameter, height: diameter)
                        .padding(.leading, segmentPadding)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity) // ⬅️ equal-width segment
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Chip
    @ViewBuilder
    private func chip(for name: String) -> some View {
        let color = colorDict[name] ?? .gray
        let isAdded = included.contains(name)
        let isFocused = focusedName == name

        Button { onTap(name) } label: {
            ZStack {


                // FOREGROUND: chip content (added = fill, not added = ring)
                if isAdded {
                    Circle()
                        .fill(color)
                        .overlay(
                            Circle()
                                .stroke(
                                    isFocused ? .white.opacity(0.75) : .white.opacity(0.25),
                                    lineWidth: isFocused ? 3 : 1
                                )
                        )
                } else {
                    Circle()
                        .stroke(color.opacity(0.95), lineWidth: ringWidth)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                                .blendMode(.overlay)
                        )

                    // At selection cap, show an x as a hint you can't add more
                    if !canSelectMore {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
//                // BACKDROP: glass circle under each chip
//                if #available(iOS 26.0, *) {
//                    Circle().glassEffect(.regular)
//                } else {
//                    Circle().fill(.ultraThinMaterial)
//                }
            }
            .scaleEffect(isFocused ? focusScale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isFocused)
            .opacity(isAdded || canSelectMore ? 1 : 0.85) // slight dim when blocked
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(name) \(isAdded ? "added" : "not added")"))
        .accessibilityHint(Text(isAdded ? "Tap to focus, tap again to remove" : "Tap to add"))
    }
}
