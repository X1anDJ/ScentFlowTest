//
//  Mix.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//


import Foundation

/// Current mix state controlled by the user.
struct Mix: Equatable, Codable {
    var selected: Set<UUID> = []
    /// Effective intensity per scent (0...AppConfig.maxIntensity).
    var intensity: [UUID: Double] = [:]
    /// Which scent is currently focused for the single-slider control (optional).
    var focused: UUID?
}
