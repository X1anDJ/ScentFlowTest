////
////  CurrentSettingsV1.swift
////  MeshGradient
////
////  Created by Dajun Xian on 9/24/25.
////
//
//
//// CurrentSettings.swift  (new file)
//import Foundation
//
///// Versioned, extensible snapshot of all user-tweakable runtime settings.
///// Add new fields with sensible defaults; keep Codable for persistence.
//struct CurrentSettingsV1: Codable, Equatable {
//    var isPowerOn: Bool
//    var fanSpeed: Double            // 0...1
//
//    // Scents / mix
//    var included: Set<String>
//    var opacities: [String: Double]
//    var focusedName: String?
//
//    init(
//        isPowerOn: Bool = false,
//        fanSpeed: Double = 0.5,
//        included: Set<String> = [],
//        opacities: [String: Double] = [:],
//        focusedName: String? = nil
//    ) {
//        self.isPowerOn = isPowerOn
//        self.fanSpeed = fanSpeed
//        self.included = included
//        self.opacities = opacities
//        self.focusedName = focusedName
//    }
//}
