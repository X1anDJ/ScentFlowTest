//
//  Device.swift
//  MeshGradient
//
//  Created by Dajun Xian on 10/10/25.
//
//  Domain model for a diffuser device
//

import Foundation

struct Device: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var insertedPods: [ScentPod]
    var isMock: Bool
    var savedSettingsBlob: Data?
    
    init(
        id: UUID = .init(),
        name: String,
        insertedPods: [ScentPod],
        isMock: Bool = false,
        savedSettingsBlob: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.insertedPods = insertedPods
        self.isMock = isMock
        self.savedSettingsBlob = savedSettingsBlob
    }
}
