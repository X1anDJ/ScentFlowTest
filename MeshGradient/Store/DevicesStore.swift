//
//  DevicesStore.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//

import SwiftUI
import Combine

struct DeviceSettings: Codable, Equatable {
    var isPowerOn: Bool
    var fanSpeed: Double        // 0...1
}

struct DeviceProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isMock: Bool
    var settings: DeviceSettings

    init(id: UUID = UUID(),
         name: String,
         isMock: Bool = false,
         settings: DeviceSettings = .init(isPowerOn: false, fanSpeed: 0.5)) {
        self.id = id
        self.name = name
        self.isMock = isMock
        self.settings = settings
    }
}

@MainActor
final class DevicesStore: ObservableObject {
    @Published var devices: [DeviceProfile]
    @Published var selectedID: UUID

    init(devices: [DeviceProfile]? = nil) {
        // Default: current “real” device + a mock one
        let defaults: [DeviceProfile] = [
            DeviceProfile(name: "Livingroom Hub",
                          isMock: false,
                          settings: .init(isPowerOn: true, fanSpeed: 0.5)),
            DeviceProfile(name: "Mock Device",
                          isMock: true,
                          settings: .init(isPowerOn: false, fanSpeed: 0.3))
        ]
        let list = devices ?? defaults
        self.devices = list
        self.selectedID = list.first?.id ?? UUID()
    }

    var selected: DeviceProfile? {
        devices.first(where: { $0.id == selectedID })
    }

    func select(_ id: UUID) {
        selectedID = id
    }

    func updateCurrentSettings(_ settings: DeviceSettings) {
        guard let idx = devices.firstIndex(where: { $0.id == selectedID }) else { return }
        devices[idx].settings = settings
    }

    func addDevice(_ profile: DeviceProfile) {
        devices.append(profile)
        selectedID = profile.id
    }
}
