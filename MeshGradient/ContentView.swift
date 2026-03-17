//
//  ContentView.swift
//  Top-level tabs. Reads the shared AppModel from the environment instead of
//  creating view-scoped stores. Keeps your existing tab structure.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppModel     //   read the shared model

    var body: some View {
        TabView {
            Tab("Control", systemImage: "circle.hexagonpath.fill") {
                NavigationStack {
                    // ControlPage now reads AppModel from the environment (no params)
                    ControlPage()
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
                    UserPage()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    // Previews need the environment object as well
    ContentView()
        .environmentObject(AppModel())
        .preferredColorScheme(.dark)
}
