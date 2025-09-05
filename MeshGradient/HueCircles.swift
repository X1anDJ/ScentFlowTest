import SwiftUI

/// A row of color circles. Solid = added; ring = not added; tap toggles and focuses.
struct HueCircles: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let focusedName: String?
    let canSelectMore: Bool
    let onTap: (String) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(names, id: \.self) { name in
                let base = colorDict[name] ?? .gray
                let isAdded = included.contains(name)
                let isFocused = focusedName == name
                
                Button {
                    onTap(name) // toggles add/remove + focuses
                } label: {
                    ZStack {
                        // Ring
                        Circle()
                            .strokeBorder(base.opacity(0.95), lineWidth: 3)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(isFocused ? 0.9 : 0), lineWidth: 2)
                                    .blur(radius: 0.2)
                            )
                        
                        // Fill when added
                        if isAdded {
                            Circle()
                                .fill(base)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .buttonStyle(.plain)
                .opacity(isAdded || canSelectMore ? 1 : 0.5) // disable when at 6
                .scaleEffect(isFocused ? 1.08 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isFocused)
                .accessibilityLabel(Text("\(name) \(isAdded ? "added" : "not added")"))
            }
        }
    }
}
