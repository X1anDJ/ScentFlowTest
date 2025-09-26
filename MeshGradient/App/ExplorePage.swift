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
                        background: {
                            Image("colorInk2")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)   // force consistent height
                                .clipped()
                        },
                        label: { Text("Unique scent make by you").font(.subheadline) }
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CustomizePodPage()
                } label: {
                    CardWithShadowContainer(
                        title: "Official Templates",
                        height: 120,
                        background: {
                            Image("mesh")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)   // force consistent height
                                .clipped()
                                .opacity(0.7)
                        },
                        label: { Text("Coming soon").font(.subheadline) }
                    )
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
