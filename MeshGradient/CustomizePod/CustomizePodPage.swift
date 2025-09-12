import SwiftUI

struct CustomizePodPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
//                Text("")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                    .padding(.leading)

                // Ball + Mixing panel (inside a Control-like card)
                MixingScreen()
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Customize Pod")
        .navigationBarTitleDisplayMode(.inline)
    }
}
