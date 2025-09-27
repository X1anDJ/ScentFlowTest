// DevicesStore.swift — load on init; persist on changes; seed only if empty

import Foundation
import SwiftUI
import Combine

extension GradientWheelViewModel {
    struct WheelSettings: Codable, Equatable {
        var isPowerOn: Bool
        var fanSpeed: Double
        var wheel: WheelSnapshot
    }
}

struct Device: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var insertedPods: [ScentPod]
    var isMock: Bool
    var savedSettings: GradientWheelViewModel.WheelSettings?

    init(
        id: UUID = .init(),
        name: String,
        insertedPods: [ScentPod],
        isMock: Bool = false,
        savedSettings: GradientWheelViewModel.WheelSettings? = nil
    ) {
        self.id = id
        self.name = name
        self.insertedPods = insertedPods
        self.isMock = isMock
        self.savedSettings = savedSettings
    }
}

@MainActor
final class DevicesStore: ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published var selectedID: UUID?

    private let repo = DevicesRepository()

    var selected: Device? { selectedID.flatMap { id in devices.first(where: { $0.id == id }) } }

    // Back-compat convenience
    var device: Device {
        get { selected ?? devices.first ?? Device(name: "My Diffuser", insertedPods: [], isMock: true) }
        set {
            if let i = devices.firstIndex(where: { $0.id == newValue.id }) { devices[i] = newValue }
            else { devices.append(newValue) }
            selectedID = newValue.id
            persist()
        }
    }

    // MARK: - Init loads persisted devices; seed only if empty
    init() {
        let loaded = (try? repo.load()) ?? (devices: [], selectedID: nil)   // ← keep labels
        self.devices = loaded.devices
        self.selectedID = loaded.selectedID ?? loaded.devices.first?.id

        if devices.isEmpty {
            seedMockIfNeeded()
            persist()
        }
    }


    // MARK: - CRUD / Selection
    func setDevices(_ list: [Device], select id: UUID? = nil) {
        devices = list
        selectedID = id ?? selectedID ?? devices.first?.id
        persist()
    }

    func select(_ id: UUID) {
        guard devices.contains(where: { $0.id == id }) else { return }
        selectedID = id
        persist()
    }

    func upsert(_ d: Device) {
        if let i = devices.firstIndex(where: { $0.id == d.id }) { devices[i] = d }
        else { devices.append(d) }
        if selectedID == nil { selectedID = d.id }
        persist()
    }

    func remove(_ id: UUID) {
        devices.removeAll { $0.id == id }
        if selectedID == id { selectedID = devices.first?.id }
        persist()
    }

    func updateCurrentSettings(_ s: GradientWheelViewModel.WheelSettings) {
        guard let id = selectedID, let i = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[i].savedSettings = s
        persist()
    }

    // MARK: - Persistence
    private func persist() {
        try? repo.save(devices: devices, selectedID: selectedID)
    }

    // MARK: - Mock seeding (runs only if no saved devices)
    func seedMockIfNeeded() {
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
        let mock = Device(name: "Living Room Diffuser", insertedPods: pods, isMock: true)
        setDevices([mock], select: mock.id)
    }
}
