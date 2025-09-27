//
//  ChildCard.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/26/25.
//

import SwiftUI

// MARK: - Nested “child card” shell (scoped to this file; not reused elsewhere)
struct ChildCard<Content: View, Trailing: View>: View {
    let title: String
    private let trailingBuilder: () -> Trailing
    @ViewBuilder var content: Content

    // NEW: optional header tap
    let onHeaderTap: (() -> Void)?

    init(
        title: String,
        onHeaderTap: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onHeaderTap = onHeaderTap
        self.trailingBuilder = trailing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            content
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.7)
                .blendMode(.overlay)
        )
    }

    @ViewBuilder
    private var header: some View {
        // Entire header is tappable; trailing is decorative (no hit testing)
        HStack {
            Text(title)
                .font(.subheadline.bold())
            Spacer()
            trailingBuilder()
                .allowsHitTesting(false)
        }
       // .padding(.vertical, 8) // larger hit target
        .contentShape(Rectangle())
        .onTapGesture {
            onHeaderTap?()
        }
        // Accessibility: expose the header as a single button when tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityHeaderLabel)
        .accessibilityAddTraits(onHeaderTap == nil ? [] : .isButton)
    }

    private var accessibilityHeaderLabel: String {
        // Helpful for VO users when the chevron is decorative
        // Example: "Pods, Expand" or "Pods, Collapse"
        guard let onHeaderTap else { return title }
        // We can't know expanded state here cleanly; keep generic
        // If you want the exact state, pass a `stateDescription` in init.
        return title
    }
}
