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
            VStack(alignment: .leading, spacing: 28) {
                profileSection
                statsSection
                purchasedProductsSection
                recordsSection
                simpleSection(title: "Community Interaction", items: communityItems)
                simpleSection(title: "Account Settings", items: settingItems)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Sections
private extension UserPage {
    var profileSection: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 92, height: 92)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 8)

            Text(profile.name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text("ID: \(profile.id) · \(profile.memberLevel) Member")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Overview")

            HStack(spacing: 12) {
                ForEach(productStats) { item in
                    UserStatCell(item: item)
                }
            }
        }
    }

    var purchasedProductsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Purchased Products")

            productTabSelector

            VStack(spacing: 12) {
                ForEach(filteredProducts) { item in
                    PurchasedProductCard(item: item)
                }
            }
        }
    }

    var recordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "My Records")

            GroupCard(spacing: 1) {
                ForEach(recordItems) { item in
                    RecordRow(item: item)
                }
            }
        }
    }

    var productTabSelector: some View {
        HStack(spacing: 8) {
            ForEach(ProductTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedProductTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedProductTab == tab ? .primary : .secondary)
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background(
                            Capsule()
                                .fill(selectedProductTab == tab
                                      ? Color.white.opacity(0.16)
                                      : Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    func simpleSection(title: String, items: [MockSimpleMenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: title)

            GroupCard(spacing: 1) {
                ForEach(items) { item in
                    SimpleMenuRow(item: item)
                }
            }
        }
    }
}

// MARK: - Reusable Components
private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 2)
    }
}

private struct GroupCard<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct UserStatCell: View {
    let item: MockUserStats

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }

            Text("\(item.value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(item.title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct PurchasedProductCard: View {
    let item: MockPurchasedItem

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if item.kind == .pod {
                    Text("Remaining: \(item.remainingText) · Last used: \(item.lastUsedText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi")
                            .font(.system(size: 13, weight: .medium))
                        Text(item.connectionText ?? "")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if let secondaryIcon = item.secondaryActionIcon {
                Button {
                } label: {
                    Image(systemName: secondaryIcon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
            }

//            Button {
//            } label: {
//                Text(item.primaryActionTitle)
//                    .font(.subheadline.weight(.medium))
//                    .foregroundStyle(.primary)
//                    .padding(.horizontal, 14)
//                    .frame(height: 34)
//                    .background(
//                        RoundedRectangle(cornerRadius: 10, style: .continuous)
//                            .fill(Color.white.opacity(0.12))
//                    )
//            }
//            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct RecordRow: View {
    let item: MockRecordItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: 28)

            Text(item.title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            if let badge = item.badgeText {
                Text(badge)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .frame(height: 22)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.white.opacity(0.02))
    }
}

private struct SimpleMenuRow: View {
    let item: MockSimpleMenuItem

    var body: some View {
        HStack {
            Text(item.title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            if item.showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
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
        name: "Dajun X",
        id: "8294567",
        memberLevel: "Gold"
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
//    let primaryActionTitle: String?
    let secondaryActionIcon: String?
    let previewColors: [Color]

    static let sample: [MockPurchasedItem] = [
        .init(
            kind: .pod,
            title: "Bluebell Pod",
            remainingText: "78%",
            lastUsedText: "Today",
            connectionText: nil,
//            primaryActionTitle: "Use",
            secondaryActionIcon: "cart.fill",
            previewColors: [Color.purple, Color.blue]
        ),
        .init(
            kind: .pod,
            title: "Lavender Pod",
            remainingText: "45%",
            lastUsedText: "Yesterday",
            connectionText: nil,
//            primaryActionTitle: "Bind",
            secondaryActionIcon: "cart.fill",
            previewColors: [Color.purple.opacity(0.85), Color.blue]
        ),
        .init(
            kind: .simulator,
            title: "ScentsFlow Pro",
            remainingText: "",
            lastUsedText: "",
            connectionText: "Connected to Bedroom",
//            primaryActionTitle: "Control",
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
        .init(icon: "shippingbox.fill", title: "My Orders", badgeText: "Pending 1"),
        .init(icon: "clock.arrow.circlepath", title: "Usage History", badgeText: "32")
    ]
}

private struct MockSimpleMenuItem: Identifiable {
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

#Preview {
    NavigationStack {
        UserPage()
    }
    .preferredColorScheme(.dark)
}
