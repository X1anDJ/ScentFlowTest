//
//  UserPageMockData.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/18/26.
//

import SwiftUI

enum ProductTab: CaseIterable {
    case all
    case pods
    case simulators

    var title: String {
        switch self {
        case .all: return "All"
        case .pods: return "Scent Pods"
        case .simulators: return "Simulators"
        }
    }
}

struct MockUserStats: Identifiable {
    let id = UUID()
    let icon: String
    let value: Int
    let title: String

    static let sample: [MockUserStats] = [
        .init(icon: "sparkles", value: 15, title: "Points"),
        .init(icon: "ticket.fill", value: 2, title: "Coupons"),
        .init(icon: "heart.fill", value: 42, title: "Likes")
    ]
}

enum PurchasedItemKind {
    case pod
    case simulator
}

struct MockPurchasedItem: Identifiable {
    let id = UUID()
    let kind: PurchasedItemKind
    let title: String
    let remainingText: String
    let lastUsedText: String
    let connectionText: String?
    let secondaryActionIcon: String?
    let previewColors: [Color]

    static let sample: [MockPurchasedItem] = [
        .init(
            kind: .pod,
            title: "Bluebell Pod",
            remainingText: "78%",
            lastUsedText: "Today",
            connectionText: nil,
            secondaryActionIcon: "cart.fill",
            previewColors: [Color.purple, Color.blue]
        ),
        .init(
            kind: .pod,
            title: "Lavender Pod",
            remainingText: "45%",
            lastUsedText: "Yesterday",
            connectionText: nil,
            secondaryActionIcon: "cart.fill",
            previewColors: [Color.purple.opacity(0.85), Color.blue]
        ),
        .init(
            kind: .simulator,
            title: "ScentsFlow Pro",
            remainingText: "",
            lastUsedText: "",
            connectionText: "Connected to Bedroom",
            secondaryActionIcon: "arrow.turn.up.right",
            previewColors: [Color.green, Color.cyan]
        )
    ]
}

struct MockRecordItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let badgeText: String?

    static let sample: [MockRecordItem] = [
        .init(icon: "cart.fill", title: "Shopping Cart", badgeText: "3"),
        .init(icon: "bookmark.fill", title: "My Favorites", badgeText: "8"),
        .init(icon: "shippingbox.fill", title: "My Orders", badgeText: "Pending 1"),
        .init(icon: "clock.arrow.circlepath", title: "Usage History", badgeText: "32")
    ]
}

struct MockSimpleMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let showsChevron: Bool

    static let communitySample: [MockSimpleMenuItem] = [
        .init(title: "My Shares", showsChevron: true),
        .init(title: "My Comments", showsChevron: true)
    ]

    static let settingsSample: [MockSimpleMenuItem] = [
        .init(title: "Settings", showsChevron: true),
        .init(title: "Help Center", showsChevron: true)
    ]
}
