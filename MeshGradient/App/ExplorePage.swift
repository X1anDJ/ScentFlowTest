//
//  ExplorePage.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//


import SwiftUI

struct ExplorePage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                NavigationLink {
                    CustomizePodPage()
                } label: {
                    CardWithShadowContainer(
                        title: "Customize Pod",
                        height: 120,
                        background: { Image("colorInk2").resizable().scaledToFit() },
                        label: { Text("Unique scent make by you").font(.subheadline) }
                    )
//                    .padding(.horizontal, 16) // <- add gutters here
                }
                .buttonStyle(.plain)


                NavigationLink {
                    CustomizePodPage()
                } label: {
                    CardWithShadowContainer(
                        title: "Master Templates",
                        height: 120,
                        background: { Image("mesh").resizable().scaledToFit() },
                        label: { Text("Coming soon").font(.subheadline) }
                    )
//                    .padding(.horizontal, 16) // <- add gutters here
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("Explore")
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
