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

                // Card 1: Customize Pod
                CardContainer(title: "Customize Pod") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All scents in one pod")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            CustomizePodPage()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Open").fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

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
