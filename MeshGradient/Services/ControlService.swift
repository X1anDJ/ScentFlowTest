//
//  ControlCommand.swift
//  MeshGradient
//
//  Created by Dajun Xian on 10/10/25.
//


//
//  ControlService.swift
//  Sends device control commands. For now, it's a stub that chooses a route
//  (BLE vs Cloud) based on "nearness". You can plug your BLE and backend later.
//

import Foundation

enum ControlCommand: Codable, Equatable {
    case applyTemplate(templateID: UUID)
    case powerOn
    case powerOff
}

@MainActor
final class ControlService {
    var remote: RemoteAPI?

    /// Sends a command to a device, preferring BLE when near, else cloud.
    func send(_ command: ControlCommand, to device: Device) {
        if isNear(device) {
            // TODO: Hook up to your BLE layer here.
            // For now: no-op.
        } else {
            // TODO: Call remote?.setDesiredState(deviceID:command:) when backend exists.
            // For now: no-op.
        }
    }

    /// Simple policy stub to decide if a device is "near".
    private func isNear(_ device: Device) -> Bool {
        // Replace with actual proximity/BLE connection state.
        return false
    }
}
