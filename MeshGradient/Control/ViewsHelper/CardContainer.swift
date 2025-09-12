import SwiftUI

/// Reusable glass card with a title row and optional trailing actions.
/// Works with both explicit and omitted `trailing:` uses.
struct CardContainer<Content: View, Trailing: View>: View {
    let title: String
    private let trailingBuilder: () -> Trailing
    private let contentBuilder: () -> Content

    init(
        title: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.trailingBuilder = trailing
        self.contentBuilder = content
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                trailingBuilder()
            }
            contentBuilder()
        }
        .padding(16)
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 16, style: .continuous))

        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
}
