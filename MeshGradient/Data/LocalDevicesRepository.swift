//
//  LocalDevicesRepository.swift
//
//  Created by Dajun Xian on 10/10/25.
//

import Foundation

protocol DevicesRepository {
    /// Loads all devices and the selected device ID from local storage.
    func loadAll() -> (devices: [Device], selectedID: UUID?)
    /// Persists devices and selected device ID atomically.
    func saveAll(devices: [Device], selectedID: UUID?)
}

struct LocalDevicesRepository: DevicesRepository {
    private let devicesKey = "devices_v2"
    private let selectedKey = "devices_selected_id_v2"

    func loadAll() -> (devices: [Device], selectedID: UUID?) {
        let devices: [Device] = {
            guard let data = UserDefaults.standard.data(forKey: devicesKey) else { return [] }
            return (try? JSONDecoder().decode([Device].self, from: data)) ?? []
        }()
        let selectedID = UserDefaults.standard.string(forKey: selectedKey).flatMap(UUID.init(uuidString:))
        return (devices, selectedID)
    }

    func saveAll(devices: [Device], selectedID: UUID?) {
        let enc = JSONEncoder()
        let data = try? enc.encode(devices)
        UserDefaults.standard.set(data, forKey: devicesKey)
        UserDefaults.standard.set(selectedID?.uuidString, forKey: selectedKey)
    }
}
