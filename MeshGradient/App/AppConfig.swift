import SwiftUI

/// Global UI/config constants for the whole app.
enum AppConfig {
    // MARK: - Scents
    /// Max number of simultaneously selected scents (chips).
    static let maxSelected: Int = 6

    // MARK: - Intensity
    /// Upper bound for a single scent's effective intensity (0...1).
    /// Keep this a `var` so you can experiment at runtime if needed.
    static var maxIntensity: Double = 0.5
    static let minIntensity: Double = 0

    // MARK: - Animations (tweak as desired)
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.9
}
