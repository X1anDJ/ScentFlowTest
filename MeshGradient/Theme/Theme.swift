//
//  Theme.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//


import SwiftUI

// MARK: - Neutral (grayscale) palette for tint + tokens you might reuse later.
enum Theme {
    enum Neutral {
        /// Light Mode tint (near-black)
        static let lightModeTint = Color(.sRGB, white: 0.3, opacity: 1.0)
        /// Dark Mode tint (near-white)
        static let darkModeTint  = Color(.sRGB, white: 0.8, opacity: 1.0)
//
//        // Optional: handy gray steps (sRGB)
//        static let gray100 = Color(.sRGB, white: 0.10, opacity: 1)
//        static let gray200 = Color(.sRGB, white: 0.20, opacity: 1)
//        static let gray300 = Color(.sRGB, white: 0.30, opacity: 1)
//        static let gray400 = Color(.sRGB, white: 0.40, opacity: 1)
//        static let gray500 = Color(.sRGB, white: 0.50, opacity: 1)
//        static let gray600 = Color(.sRGB, white: 0.60, opacity: 1)
//        static let gray700 = Color(.sRGB, white: 0.70, opacity: 1)
//        static let gray800 = Color(.sRGB, white: 0.80, opacity: 1)
//        static let gray900 = Color(.sRGB, white: 0.90, opacity: 1)
    }
}

// MARK: - A single modifier to apply grayscale tint app-wide.
private struct GrayscaleTintModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    private var currentTint: Color {
        scheme == .dark ? Theme.Neutral.darkModeTint : Theme.Neutral.lightModeTint
    }

    func body(content: Content) -> some View {
        content
            .tint(currentTint)  // SwiftUI components (buttons, links, toggles, etc.)
            .onAppear { applyUIKitTint() }
            .onChange(of: scheme) { _ in applyUIKitTint() } // live-update on mode changes
    }

    private func applyUIKitTint() {
        #if canImport(UIKit)
        let uiTint = UIColor(currentTint)
        // Common bar controls
        UINavigationBar.appearance().tintColor = uiTint
        UITabBar.appearance().tintColor       = uiTint
        UIBarButtonItem.appearance().tintColor = uiTint

        // If you use segmented controls and want a subtle gray fill, uncomment:
        // UISegmentedControl.appearance().selectedSegmentTintColor = uiTint.withopacityComponent(0.2)
        #endif
    }
}

public extension View {
    /// Apply a black/white (grayscale) tint that adapts to Light/Dark mode.
    func applyGrayscaleTint() -> some View {
        modifier(GrayscaleTintModifier())
    }
}
