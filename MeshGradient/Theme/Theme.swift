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


extension Theme {
    // Base wheel's white/black shadow for gradient mesh circle
    enum Shadow {
        static let wheelLight = Color.black.opacity(0.2)
        static let wheelDark  = Color.white.opacity(0.7)
    }
    
}

extension Theme {
    enum CircleFill {
        static let innerLight = Color.gray.opacity(0.1)
        static let outerLight = Color.gray.opacity(0)
        static let innerDark  = Color.white.opacity(0.14)
        static let outerDark  = Color.white.opacity(0.02)

        static func WhiteShadowGradient(for scheme: ColorScheme, radius: CGFloat) -> RadialGradient {
            let inner = (scheme == .dark) ? innerDark : innerLight
            let outer = (scheme == .dark) ? outerDark : outerLight
            return RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: inner, location: 0.0),
                    .init(color: outer, location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: radius
            )
        }
    }
}

// MARK: - Background hierarchy tokens
extension Theme {
    enum Background {
        // Page-level backgrounds
        static let canvas = Color(uiColor: .systemBackground)
        static let groupedCanvas = Color(uiColor: .systemGroupedBackground)

        // Section/group backgrounds
        static let surface = Color(uiColor: .secondarySystemBackground)
        static let insetSurface = Color(uiColor: .tertiarySystemBackground)

        // Semantic lines / borders / fills
        static let separator = Color(uiColor: .separator)
        static let opaqueSeparator = Color(uiColor: .opaqueSeparator)
        static let softFill = Color(uiColor: .quaternarySystemFill)
        static let mediumFill = Color(uiColor: .tertiarySystemFill)

        // ShapeStyle-based materials for elevated UI
        static func cardStyle(for scheme: ColorScheme) -> AnyShapeStyle {
            switch scheme {
            case .dark:
                return AnyShapeStyle(.regularMaterial)
            case .light:
                return AnyShapeStyle(Color(uiColor: .secondarySystemBackground))
            @unknown default:
                return AnyShapeStyle(Color(uiColor: .secondarySystemBackground))
            }
        }

        static func floatingStyle(for scheme: ColorScheme) -> AnyShapeStyle {
            switch scheme {
            case .dark:
                return AnyShapeStyle(.thickMaterial)
            case .light:
                return AnyShapeStyle(.regularMaterial)
            @unknown default:
                return AnyShapeStyle(.regularMaterial)
            }
        }

        static func controlStyle(for scheme: ColorScheme) -> AnyShapeStyle {
            switch scheme {
            case .dark:
                return AnyShapeStyle(.thinMaterial)
            case .light:
                return AnyShapeStyle(Color(uiColor: .tertiarySystemBackground))
            @unknown default:
                return AnyShapeStyle(Color(uiColor: .tertiarySystemBackground))
            }
        }

        static var ultraThinMaterialStyle: AnyShapeStyle {
            AnyShapeStyle(.ultraThinMaterial)
        }

        static var thinMaterialStyle: AnyShapeStyle {
            AnyShapeStyle(.thinMaterial)
        }

        static var regularMaterialStyle: AnyShapeStyle {
            AnyShapeStyle(.regularMaterial)
        }

        static var thickMaterialStyle: AnyShapeStyle {
            AnyShapeStyle(.thickMaterial)
        }
    }
}
