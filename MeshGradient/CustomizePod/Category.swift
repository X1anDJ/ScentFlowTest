//
//  Category.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//
import SwiftUI

enum Category: CaseIterable {
    case red, orange, brown, yellow, green, cyan, violet
    var color: Color {
        switch self {
        case .red:    return .red
        case .orange: return .orange
        case .brown:  return .brown
        case .yellow: return .yellow
        case .green:  return .green
        case .cyan:   return .cyan
        case .violet: return .purple
        }
    }
    var label: String {
        switch self {
        case .red: return "Warm"
        case .orange: return "Fruit"
        case .brown: return "Woody"
        case .yellow: return "Flower"
        case .green:  return "Grass"
        case .cyan:   return "Ozonic"
        case .violet: return "Mystery"
        }
    }
    var displayName: String { label }
    var optionsEN: [String] {
        switch self {
        case .red:    return ["Pepper","Cinnamon","Clove"]
        case .orange: return ["Orange","Lemon","Grapefruit"]
        case .brown:  return ["Sandalwood","Cedar","Pine"]
        case .yellow: return ["Jasmine","Rose","Osmanthus"]
        case .green:  return ["Mint","Green Leaves","Fresh Grass"]
        case .cyan:   return ["Sea Breeze","Water Vapor","Petrichor"]
        case .violet: return ["Vanilla","Resin","Frankincense"]
        }
    }
}
