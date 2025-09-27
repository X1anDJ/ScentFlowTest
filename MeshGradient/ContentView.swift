import SwiftUI

struct ContentView: View {
    @StateObject private var devices = DevicesStore()
    @StateObject private var templatesStore = TemplatesStore()

    var body: some View {
        TabView {
            Tab("Control", systemImage: "circle.hexagonpath.fill") {
                NavigationStack {
                    ControlPage(devices: devices, templatesStore: templatesStore)
                        .customTopBar("ScentsFlow")
                }
            }

            Tab("Explore", systemImage: "sparkles") {
                NavigationStack {
                    ExplorePage()
                        .customTopBar("Explore")
                }
            }

            Tab("User", systemImage: "person.fill") {
                NavigationStack {
                    Text("More coming soon")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .customTopBar("User")
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView().preferredColorScheme(.dark)
}
