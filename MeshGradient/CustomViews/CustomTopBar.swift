//
//  CustomTopBar.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/27/25.
//


import SwiftUI

// MARK: - Reusable Top Bar

struct CustomTopBar<Leading: View, Trailing: View>: View {
    let title: String
    let leading: Leading
    let trailing: Trailing

    init(title: String,
         @ViewBuilder leading: () -> Leading,
         @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            leading
            Text(title)
                .font(.largeTitle.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.clear) // swap to `.bar` if you want a nav-bar look
    }
}

// MARK: - View Modifier + Convenience API

struct WithCustomTopBar<Leading: View, Trailing: View>: ViewModifier {
    let title: String
    let leading: () -> Leading
    let trailing: () -> Trailing

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                CustomTopBar(title: title, leading: leading, trailing: trailing)
            }
    }
}

extension View {
    func customTopBar<Leading: View, Trailing: View>(
        _ title: String,
        @ViewBuilder leading: @escaping () -> Leading = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) -> some View {
        modifier(WithCustomTopBar(title: title, leading: leading, trailing: trailing))
    }
}
