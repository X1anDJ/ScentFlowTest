import SwiftUI

@main
struct MeshGradientApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .applyGrayscaleTint()
        }
    }
}
