import SwiftUI

struct CustomizePodPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Headline under the large nav title
                Text("All scents in one pod")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    

                // Ball + Mixing panel (inside a Control-like card)
                MixingScreen()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Customize Pod")
        .navigationBarTitleDisplayMode(.large)
    }
}
