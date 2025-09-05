//
//  AppConfig.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/5/25.
//


import Foundation

/// Global UI/config constants.
/// Change `maxIntensity` once to affect all intensity sliders.
enum AppConfig {
    /// Maximum *effective* intensity applied to colors (0...1).
    /// Example: 0.8 means a 100% slider position applies 0.8 to the color.
    static var maxIntensity: Double = 0.6
}
