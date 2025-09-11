import SwiftUI

/// A horizontal row of scent color circles.
/// - Added scents: solid filled disk
/// - Not added: a ring (stroke only)
/// Tapping uses your VM's 3-state toggle (off → on+focus → focus → off).
struct HueCircles: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let focusedName: String?
    let canSelectMore: Bool
    let onTap: (String) -> Void

    // Visual constants
    private let diameter: CGFloat = 28
    private let ringWidth: CGFloat = 2
    private let focusScale: CGFloat = 1.08

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(names, id: \.self) { name in
                    let color = colorDict[name] ?? .gray
                    let isAdded = included.contains(name)
                    let isFocused = focusedName == name

                    Button { onTap(name) } label: {
                        ZStack {
                            if isAdded {
                                // ADDED: solid disk
                                Circle()
                                    .fill(color)
                                    .frame(width: diameter, height: diameter)
                                    .overlay(
                                        Circle()
                                            .stroke(isFocused ? .white.opacity(0.75) : .white.opacity(0.25),
                                                    lineWidth: isFocused ? 3 : 1)
                                    )
                            } else {
                                // NOT ADDED: color ring
                                Circle()
                                    .stroke(color.opacity(0.95), lineWidth: ringWidth)
                                    .frame(width: diameter, height: diameter)
                                    .overlay(
                                        // subtle inner highlight for glassy look
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
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        }
    }
}
