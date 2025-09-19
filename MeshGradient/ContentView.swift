import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Control", systemImage: "circle.hexagonpath.fill") {
                NavigationStack {
                    ControlPage() // root contains a ScrollView
                }
            }
            Tab("Explore", systemImage: "sparkles") {
                NavigationStack { ExplorePage() }
            }
            Tab("User", systemImage: "person.fill") {
                NavigationStack {
                    Text("More coming soon")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle("User")
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}


#Preview {
    ContentView().preferredColorScheme(.dark)
}
