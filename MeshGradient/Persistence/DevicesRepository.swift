//
//  DevicesRepository.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/26/25.
//


// DevicesRepository.swift  — tiny persistence helper for devices

import Foundation

struct DevicesRepository {
    private let devicesKey = "devices_v1"
    private let selectedKey = "devices_selected_id_v1"

    func save(devices: [Device], selectedID: UUID?) throws {
        let enc = JSONEncoder()
        let data = try enc.encode(devices)
        UserDefaults.standard.set(data, forKey: devicesKey)
        UserDefaults.standard.set(selectedID?.uuidString, forKey: selectedKey)
    }

    func load() throws -> (devices: [Device], selectedID: UUID?) {
        let dec = JSONDecoder()
        let devices: [Device] = {
            guard let data = UserDefaults.standard.data(forKey: devicesKey) else { return [] }
            return (try? dec.decode([Device].self, from: data)) ?? []
        }()
        let selectedID: UUID? = {
            guard let s = UserDefaults.standard.string(forKey: selectedKey) else { return nil }
            return UUID(uuidString: s)
        }()
        return (devices, selectedID)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: devicesKey)
        UserDefaults.standard.removeObject(forKey: selectedKey)
    }
}
