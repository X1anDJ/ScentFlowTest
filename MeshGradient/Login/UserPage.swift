//
//  UserPage.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/18/26.
//


import SwiftUI

struct UserPage: View {
    @EnvironmentObject private var authSession: AuthSession

    @State private var selectedProductTab: ProductTab = .all
    @State private var showLogin = false

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

    private var displayName: String {
        authSession.currentUser?.name ?? "Guest"
    }

    private var profileSubtitle: String {
        if let user = authSession.currentUser {
            return "ID: \(user.id) · \(user.memberLevel) Member"
        }
        return "Tap to sign in"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                profileSection

                if authSession.isLoggedIn {
                    statsSection
                    purchasedProductsSection
                    recordsSection
                    simpleSection(title: "Community Interaction", items: communityItems)
                } else {
//                    guestPromptSection
                }

                accountSettingsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showLogin) {
            NavigationStack {
                LoginView()
                    .environmentObject(authSession)
            }
        }
        
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
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 42, weight: .regular))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(.top, 8)

            Text(displayName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                Text(profileSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !authSession.isLoggedIn {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !authSession.isLoggedIn else { return }
            showLogin = true
        }
    }

    var guestPromptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Sign In")

            GroupCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Use the test account below to verify the login flow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone: +86 16666666666")
                        Text("SMS Code: 0000")
                        Text("Password: 0000")
                    }
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)

                    Button {
                        showLogin = true
                    } label: {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
            }
        }
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

    var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Account Settings")

            GroupCard(spacing: 1) {
                ForEach(settingItems) { item in
                    SimpleMenuRow(item: item)
                }

                if authSession.isLoggedIn {
                    LogoutRow {
                        authSession.logout()
                    }
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
                                .fill(
                                    selectedProductTab == tab
                                    ? Color.white.opacity(0.16)
                                    : Color.white.opacity(0.06)
                                )
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

private struct LogoutRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("Log Out")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(Color.white.opacity(0.02))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Guest") {
    NavigationStack {
        UserPage()
    }
    .environmentObject(AuthSession())
    .preferredColorScheme(.dark)
}

#Preview("Logged In") {
    NavigationStack {
        UserPage()
    }
    .environmentObject(AuthSession.previewLoggedIn)
    .preferredColorScheme(.dark)
}
