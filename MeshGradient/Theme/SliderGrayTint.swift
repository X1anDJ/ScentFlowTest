//
//  SliderGrayTint.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//


import SwiftUI

/// A per-control tint that’s more "gray" than your global tint.
/// Defaults give you a mid-gray: darker than white in Dark Mode, lighter than black in Light Mode.
public struct SliderGrayTint: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    /// Light Mode whiteness (0 = black, 1 = white). Default 0.25 ~ dark gray.
    var lightWhite: Double
    /// Dark Mode whiteness. Default 0.75 ~ light gray.
    var darkWhite: Double
    /// opacity channel if you want a softer tint. Default 1.0 (opaque).
    var opacity: Double

    public func body(content: Content) -> some View {
        let w = scheme == .dark ? darkWhite : lightWhite
        return content.tint(Color(.sRGB, white: w, opacity: opacity))
    }
}

public extension View {
    /// Apply a grayer tint *just* to this view (e.g., a Slider).
    /// - Parameters:
    ///   - lightWhite: 0…1 whiteness for Light Mode (default 0.25).
    ///   - darkWhite:  0…1 whiteness for Dark Mode  (default 0.75).
    ///   - opacity:      0…1 opacity (default 1).
    func sliderTintGray(lightWhite: Double = 0.4,
                        darkWhite: Double = 0.75,
                        opacity: Double = 1.0) -> some View {
        modifier(SliderGrayTint(lightWhite: lightWhite, darkWhite: darkWhite, opacity: opacity))
    }
}
