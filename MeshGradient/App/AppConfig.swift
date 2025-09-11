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
