//
//  CardContainer.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/5/25.
//


// CardContainer.swift
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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 0.8)
                        .blendMode(.overlay)
                )
            
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
        )
        
    }

}
