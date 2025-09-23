import SwiftUI

struct CardWithShadowContainer<LabelContent: View, Background: View>: View {
    let title: String?
    let height: CGFloat
    private let labelContent: () -> LabelContent
    private let background: () -> Background

    init(
        title: String? = nil,
        height: CGFloat = 120,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder label: @escaping () -> LabelContent
    ) {
        self.title = title
        self.height = height
        self.background = background
        self.labelContent = label
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background (scaledToFill supplied by caller)
            background()

            // Readability scrim
            LinearGradient(
                colors: [Color.black.opacity(0.25), .clear, .clear, Color.black.opacity(0.35)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                
                Spacer(minLength: 0)
                // Optional title near top-leading
                if let title, !title.isEmpty {
                    Text(title)
                        .font(Font.title2.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                        .padding(.horizontal, 16)
                }

                labelContent()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

//                // Bottom description area
//                HStack(spacing: 12) {
//                    labelContent()
//                        .foregroundStyle(.white)
//                }
////                .padding(.horizontal, 16)
////                .padding(.vertical, 12)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .background(.ultraThinMaterial)
////                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
////                .padding(12)
            }
        }
//        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 12)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous)) // large hit target when wrapped
    }
}
