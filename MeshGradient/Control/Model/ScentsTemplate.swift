//
//  ScentsTemplate.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/26/25.
//


import Foundation

/// Template references the pods by *pod IDs*
/// (simple, no extra stores; templates are naturally device-scoped)
public struct ScentsTemplate: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var scentPodIDs: [UUID]   // ordered

    public init(id: UUID = .init(), name: String, scentPodIDs: [UUID]) {
        self.id = id
        self.name = name
        self.scentPodIDs = scentPodIDs
    }
}
