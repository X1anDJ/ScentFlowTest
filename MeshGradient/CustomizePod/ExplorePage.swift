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
                        height: 260,
                        background: { Image("colorInk2").resizable().scaledToFill() },
                        label: { Text("Unique scent make by you").font(.subheadline) }
                    )
//                    .padding(.horizontal, 16) // <- add gutters here
                }
                .buttonStyle(.plain)




                // Card 2: Scents Templates (placeholder)
                CardContainer(title: "Scents Templates") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Coming soon")
                            .foregroundStyle(.secondary)
                        // You can later navigate to your templates screen here.
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Explore")
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
