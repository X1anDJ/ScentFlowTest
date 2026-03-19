//
//  SocialLoginButton.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/18/26.
//


import SwiftUI

struct SocialLoginButton: View {
    enum IconSource {
        case system(String)
        case asset(String)
    }

    let icon: IconSource
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(tint.opacity(0.45), lineWidth: 1)

                iconView
            }
            .frame(width: 54, height: 54)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(tint)

        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}