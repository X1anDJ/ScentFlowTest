//
//  Device.swift
//  MeshGradient
//
//  Created by Dajun Xian on 10/10/25.
//


//
//  Device.swift
//  Domain model for a diffuser device. Minimal & UI-friendly.
//

import Foundation

struct Device: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var insertedPods: [ScentPod]       // assumes your existing ScentPod model
    var isMock: Bool
    var savedSettingsBlob: Data?       // opaque wheel/settings snapshot (future-proof)

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
