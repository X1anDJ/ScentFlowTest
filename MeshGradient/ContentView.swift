import SwiftUI

struct ContentView: View {
    
    @StateObject private var devices = DevicesStore()
    @StateObject private var templatesStore = TemplatesStore()
    
    var body: some View {
        TabView {
            Tab("Control", systemImage: "circle.hexagonpath.fill") {
                NavigationStack {
                    ControlPage(devices: devices, templatesStore: templatesStore) // root contains a ScrollView
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
        //.contentTransition(.symbolEffect(.replace)): Smooth symbol replacement for SFSymbols.
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}


#Preview {
    ContentView().preferredColorScheme(.dark)
}
