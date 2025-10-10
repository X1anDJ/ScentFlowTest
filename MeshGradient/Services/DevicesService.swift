//
//  DevicesService.swift
//  MeshGradient
//
//  Created by Dajun Xian on 10/10/25.
//


//
//  DevicesService.swift
//  Owns devices in memory, selection, and simple actions.
//

import SwiftUI
import Foundation
import Combine

@MainActor
final class DevicesService: ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published var selectedID: UUID?

    private let local: DevicesRepository
    // Optional future dependencies
    var remote: RemoteAPI?

    init(local: DevicesRepository) {
        self.local = local
    }

    /// Loads devices + selection from local storage into memory.
    func load() {
        let loaded = local.loadAll()
        devices = loaded.devices
        selectedID = loaded.selectedID ?? devices.first?.id

        if devices.isEmpty {
            seedMockIfNeeded()
            persist()
        }
    }

    /// The currently selected device, if any.
    var selected: Device? {
        guard let id = selectedID else { return nil }
        return devices.first(where: { $0.id == id })
    }

    /// Selects a device by ID and persists selection.
    func select(_ id: UUID) {
        guard devices.contains(where: { $0.id == id }) else { return }
        selectedID = id
        persist()
    }

    /// Inserts or updates a device and persists.
    func upsert(_ d: Device) {
        if let i = devices.firstIndex(where: { $0.id == d.id }) { devices[i] = d }
        else { devices.append(d) }
        if selectedID == nil { selectedID = d.id }
        persist()
    }

    /// Removes a device and keeps selection sensible.
    func remove(_ id: UUID) {
        devices.removeAll { $0.id == id }
        if selectedID == id { selectedID = devices.first?.id }
        persist()
    }

    /// Saves an opaque settings snapshot on the selected device.
    func saveSettingsBlobForSelected(_ data: Data) {
        guard let id = selectedID, let i = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[i].savedSettingsBlob = data
        persist()
    }

    /// Writes devices + selection to local storage.
    private func persist() {
        local.saveAll(devices: devices, selectedID: selectedID)
    }

    /// Seeds two mock devices for first launch.
    private func seedMockIfNeeded() {
        guard devices.isEmpty else { return }
        let pods: [ScentPod] = [
            ScentPod(name: "Pepper",     color: .red,    remainTime:  90*60),
            ScentPod(name: "Orange",     color: .orange, remainTime: 120*60),
            ScentPod(name: "Lemon",      color: .yellow, remainTime:  80*60),
            ScentPod(name: "Mint",       color: .green,  remainTime: 110*60),
            ScentPod(name: "Ocean",      color: .cyan,   remainTime: 100*60),
            ScentPod(name: "Bluebell",   color: .blue,   remainTime:  95*60),
            ScentPod(name: "Sandalwood", color: .purple, remainTime: 130*60),
        ]
        let a = Device(name: "Living Room", insertedPods: pods, isMock: true)
        let b = Device(name: "Bedroom", insertedPods: pods, isMock: true)
        devices = [a, b]
        selectedID = a.id
    }
}
