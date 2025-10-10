//
//  LocalDevicesRepository.swift
//
//  Created by Dajun Xian on 10/10/25.
//

import Foundation

protocol DevicesRepository {
    func loadAll() async -> (devices: [Device], selectedID: UUID?)
    func saveAll(devices: [Device], selectedID: UUID?) async
}

// LocalDevicesRepository.swift
struct LocalDevicesRepository: DevicesRepository {
    private let devicesKey = "devices_v2"
    private let selectedKey = "devices_selected_id_v2"

    func loadAll() async -> (devices: [Device], selectedID: UUID?) {
        await Task.detached(priority: .utility) {
            let devices: [Device] = {
                guard let data = UserDefaults.standard.data(forKey: devicesKey) else { return [] }
                return (try? JSONDecoder().decode([Device].self, from: data)) ?? []
            }()
            let selectedID = UserDefaults.standard
                .string(forKey: selectedKey)
                .flatMap(UUID.init(uuidString:))
            return (devices, selectedID)
        }.value
    }

    func saveAll(devices: [Device], selectedID: UUID?) async {
        await Task.detached(priority: .utility) {
            let enc = JSONEncoder()
            let data = try? enc.encode(devices)
            UserDefaults.standard.set(data, forKey: devicesKey)
            UserDefaults.standard.set(selectedID?.uuidString, forKey: selectedKey)
        }.value
    }
}
