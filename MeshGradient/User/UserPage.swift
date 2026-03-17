//
//  UserPage.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/17/26.
//


//
//  UserPage.swift
//  MeshGradient
//

import SwiftUI

struct UserPage: View {
    @State private var selectedProductTab: ProductTab = .all

    private let profile = MockUserProfile.sample
    private let productStats = MockUserStats.sample
    private let purchasedProducts = MockPurchasedItem.sample
    private let recordItems = MockRecordItem.sample
    private let communityItems = MockSimpleMenuItem.communitySample
    private let settingItems = MockSimpleMenuItem.settingsSample

    private var filteredProducts: [MockPurchasedItem] {
        switch selectedProductTab {
        case .all:
            return purchasedProducts
        case .pods:
            return purchasedProducts.filter { $0.kind == .pod }
        case .simulators:
            return purchasedProducts.filter { $0.kind == .simulator }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileSection

                DividerSectionSpacer()

                statsSection

                DividerSectionSpacer()

                purchasedProductsSection

                DividerSectionSpacer(top: 28)

                recordsSection

                DividerSectionSpacer(top: 28)

                simpleSection(
                    title: "Community Interaction",
                    items: communityItems
                )

                DividerSectionSpacer(top: 28)

                simpleSection(
                    title: "Account Settings",
                    items: settingItems
                )

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Sections
private extension UserPage {
    var profileSection: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 96, height: 96)
                .padding(.top, 18)

            Text(profile.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("ID: \(profile.id) | Member Level: \(profile.memberLevel)")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 22)
    }

    var statsSection: some View {
        HStack(spacing: 0) {
            ForEach(productStats) { item in
                UserStatCell(item: item)

                if item.id != productStats.last?.id {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 24)
    }

    var purchasedProductsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "Purchased Products")

            productTabSelector

            VStack(spacing: 14) {
                ForEach(filteredProducts) { item in
                    PurchasedProductCard(item: item)
                }
            }
        }
        .padding(.top, 22)
    }

    var recordsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "My Records")

            VStack(spacing: 1) {
                ForEach(recordItems) { item in
                    RecordRow(item: item)
                }
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 0))
        }
    }

    var productTabSelector: some View {
        HStack(spacing: 10) {
            ForEach(ProductTab.allCases, id: \.self) { tab in
                Button {
                    selectedProductTab = tab
                } label: {
                    Text(tab.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selectedProductTab == tab ? .white : .white.opacity(0.9))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(selectedProductTab == tab ? Color.blue : Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    func simpleSection(title: String, items: [MockSimpleMenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: title)

            VStack(spacing: 1) {
                ForEach(items) { item in
                    SimpleMenuRow(item: item)
                }
            }
            .background(Color.white.opacity(0.08))
        }
    }
}

// MARK: - Components
private struct DividerSectionSpacer: View {
    var top: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .padding(.top, top)
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3, height: 24)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

private struct UserStatCell: View {
    let item: MockUserStats

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.blue)
                }

            Text("\(item.value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text(item.title)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PurchasedProductCard: View {
    let item: MockPurchasedItem

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: item.previewColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay {
                    if item.kind == .simulator {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                if item.kind == .pod {
                    Text("Remaining: \(item.remainingText) | Last\nused: \(item.lastUsedText)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi")
                            .font(.system(size: 14, weight: .medium))
                        Text(item.connectionText ?? "")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.green)
                }
            }

            Spacer(minLength: 0)

            if let secondaryIcon = item.secondaryActionIcon {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 42, height: 32)
                    .overlay {
                        Image(systemName: secondaryIcon)
                            .foregroundStyle(.white.opacity(0.75))
                    }
            }

            Button {
            } label: {
                Text(item.primaryActionTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.09))
        )
    }
}

private struct RecordRow: View {
    let item: MockRecordItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.blue)
                .frame(width: 34)

            Text(item.title)
                .font(.system(size: 17))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            if let badge = item.badgeText {
                Text(badge)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 22)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .background(Color.white.opacity(0.02))
    }
}

private struct SimpleMenuRow: View {
    let item: MockSimpleMenuItem

    var body: some View {
        HStack {
            Text(item.title)
                .font(.system(size: 17))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            if item.showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .background(Color.white.opacity(0.02))
    }
}

// MARK: - Mock Models
private enum ProductTab: CaseIterable {
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

private struct MockUserProfile {
    let name: String
    let id: String
    let memberLevel: String

    static let sample = MockUserProfile(
        name: "Luna_Scents",
        id: "8294567",
        memberLevel: "Silver"
    )
}

private struct MockUserStats: Identifiable {
    let id = UUID()
    let icon: String
    let value: Int
    let title: String

    static let sample: [MockUserStats] = [
        .init(icon: "cylinder.split.1x2.fill", value: 15, title: "My Points"),
        .init(icon: "ticket.fill", value: 2, title: "Coupons"),
        .init(icon: "heart.fill", value: 42, title: "Likes")
    ]
}

private enum PurchasedItemKind {
    case pod
    case simulator
}

private struct MockPurchasedItem: Identifiable {
    let id = UUID()
    let kind: PurchasedItemKind
    let title: String
    let remainingText: String
    let lastUsedText: String
    let connectionText: String?
    let primaryActionTitle: String
    let secondaryActionIcon: String?
    let previewColors: [Color]

    static let sample: [MockPurchasedItem] = [
        .init(
            kind: .pod,
            title: "Bluebell Pod",
            remainingText: "78%",
            lastUsedText: "Today",
            connectionText: nil,
            primaryActionTitle: "Use",
            secondaryActionIcon: "cart.fill",
            previewColors: [Color.purple, Color.blue]
        ),
        .init(
            kind: .pod,
            title: "Lavender Pod",
            remainingText: "45%",
            lastUsedText: "Yesterday",
            connectionText: nil,
            primaryActionTitle: "bind",
            secondaryActionIcon: "cart.fill",
            previewColors: [Color.purple.opacity(0.85), Color.blue]
        ),
        .init(
            kind: .simulator,
            title: "ScentsFlow Pro\nSimulator",
            remainingText: "",
            lastUsedText: "",
            connectionText: "Connected to Bedroom",
            primaryActionTitle: "Control",
            secondaryActionIcon: "arrow.turn.up.right",
            previewColors: [Color.green, Color.cyan]
        )
    ]
}

private struct MockRecordItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let badgeText: String?

    static let sample: [MockRecordItem] = [
        .init(icon: "cart.fill", title: "Shopping Cart", badgeText: "3"),
        .init(icon: "bookmark.fill", title: "My Favorites", badgeText: "8"),
        .init(icon: "shippingbox.fill", title: "My Orders", badgeText: "Pending(1)"),
        .init(icon: "clock.arrow.circlepath", title: "Usage History", badgeText: "32")
    ]
}

private struct MockSimpleMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let showsChevron: Bool

    static let communitySample: [MockSimpleMenuItem] = [
        .init(title: "My Shares", showsChevron: false),
        .init(title: "My Comments", showsChevron: false)
    ]

    static let settingsSample: [MockSimpleMenuItem] = [
        .init(title: "Settings", showsChevron: false),
        .init(title: "Help Center", showsChevron: false)
    ]
}

#Preview {
    NavigationStack {
        UserPage()
            .customTopBar("My Account")
    }
    .preferredColorScheme(.dark)
}