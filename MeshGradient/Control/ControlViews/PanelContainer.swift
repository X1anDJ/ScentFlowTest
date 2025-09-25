//
//  PanelContainer.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/24/25.
//


import SwiftUI

/// Reusable glass card with a title row and optional trailing actions.
/// Works with both explicit and omitted `trailing:` uses.
struct PanelContainer<Content: View, Trailing: View, Background: View>: View {
    let title: String
   // private let trailingBuilder: () -> Trailing
    private let contentBuilder: () -> Content
    private let backgroundBuilder: () -> Background

    init(
        title: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder background: @escaping () -> Background = { Color.clear },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        //self.trailingBuilder = trailing
        self.backgroundBuilder = background
        self.contentBuilder = content
    }

    var body: some View {
        ZStack {
            backgroundBuilder()
//                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            contentBuilder()
                .frame(maxHeight: .infinity, alignment: .top)
//            VStack(spacing: 12) {
//                HStack {
//                    trailingBuilder()
//                }
//            }
//            .padding(.horizontal, 16)
        }
        
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 16, style: .continuous))
        //.shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 10)
    }
}
