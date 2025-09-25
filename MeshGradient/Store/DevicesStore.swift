// DevicesStore.swift
import SwiftUI
import Combine

// (Remove the old DeviceSettings struct) 

// New profiles now store the whole current settings snapshot
struct DeviceProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isMock: Bool
    var settings: CurrentSettingsV1

    init(
        id: UUID = UUID(),
        name: String,
        isMock: Bool = false,
        settings: CurrentSettingsV1 = .init(isPowerOn: false, fanSpeed: 0.5)
    ) {
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
        // Defaults keep working
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

    func select(_ id: UUID) { selectedID = id }

    // Save whole snapshot
    func updateCurrentSettings(_ snapshot: CurrentSettingsV1) {
        guard let idx = devices.firstIndex(where: { $0.id == selectedID }) else { return }
        devices[idx].settings = snapshot
    }

    // Helper to read the snapshot for the selected device
    func currentSettings() -> CurrentSettingsV1? {
        selected?.settings
    }
}
