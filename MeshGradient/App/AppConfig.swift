import SwiftUI

/// Global configuration & design tokens.
enum AppConfig {
    // MARK: - Mix rules
    static let maxSelected: Int = 6
    static var maxIntensity: Double = 0.5
    static let minIntensity: Double = 0.0

    // MARK: - Device
    static let fanRange: ClosedRange<Double> = 0.0...1.0
    static let defaultFanSpeed: Double = 0.35

    // MARK: - Animations
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.9
}

// MARK: - Gradient Container Circle Theme Tokens
extension AppConfig {
    
    struct GradientCircleTokens {
        // Halo (outside of the rim)
        let glowStartInset: CGFloat     // negative → start inside rim; positive → outside
        let glowRadiusAdded: CGFloat    // fade extent beyond rim
        let glowSoftness: CGFloat
        let glowOpacity: Double

        // Ring
        let rimWidth: CGFloat

        // Color treatment
        let colorUpperBound: Double
        let colorAlphaScale: Double     // multiply incoming color alphas
        
    }

    /// Returns the tokens for the gradient circle given the current color scheme.
    /// Tweak these numbers to taste; the goal is a softer, subtler look in light mode.
    static func gradientCircleTokens(for colorScheme: ColorScheme) -> GradientCircleTokens {
        switch colorScheme {
        case .dark:
            return GradientCircleTokens(
                glowStartInset: -4,
                glowRadiusAdded: 80,
                glowSoftness: 68,
                glowOpacity: 0.7,
                rimWidth: 8,
                colorUpperBound: 0.8,
                colorAlphaScale: 1.25
            )
        default:
            return GradientCircleTokens(
                glowStartInset: -4,     // start a touch closer to the rim
                glowRadiusAdded: 58,    // slightly tighter halo in light mode
                glowSoftness: 50,
                glowOpacity: 0.48,       
                rimWidth: 8,
                colorUpperBound: 0.65,
                colorAlphaScale: 0.85
            )
        }
    }
}
