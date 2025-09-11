//  CardContainer.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/5/25.
//

import SwiftUI

struct CardContainer<Content: View>: View {
    let title: String
    let trailing: AnyView?
    let content: () -> Content

    init(title: String, trailing: some View = EmptyView(), @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.trailing = AnyView(trailing)
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                trailing
            }

            content()
        }
        .padding(16)
        // Glass (iOS 26+) or ultraThinMaterial fallback in a rounded rect
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Keep your subtle edge highlight
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 0.8)
                .blendMode(.overlay)
        )
        // Original shadow
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
}
