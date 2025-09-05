import SwiftUI

/// Glassy (Liquid-Glass-style) circle for the 0-color state.
/// Works on today’s SDKs (no .glassEffect required).
struct GlassyCircle: View {
    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                Circle()
                    .inset(by: 6)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    .blur(radius: 0.5)
                    .blendMode(.overlay)
            )
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
                    .opacity(0.7)
            )
            .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}
