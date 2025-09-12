import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // CONTROL
            ControlPage()
                .tabItem {
                    Image(systemName: "circle.hexagonpath.fill")
                    Text("Control")
                }

            // SECOND TAB (placeholder)
            NavigationStack {
                ExplorePage()
            }
            .tabItem {
                Image(systemName: "sparkles")
                Text("Explore")
            }

            // THIRD TAB (placeholder)
            NavigationStack {
                Text("More coming soon")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("User")
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("User")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView().preferredColorScheme(.dark)
}
