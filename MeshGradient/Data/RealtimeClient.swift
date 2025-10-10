//
//  RealtimeClient.swift
//  Protocol for future WebSocket/MQTT updates; stubbed for now.
//
//  Created by Dajun Xian on 10/10/25.
//

import Foundation

enum RealtimeEvent {
    case templateUpdated(ScentsTemplate)
    case templateDeleted(UUID)
    case deviceStateChanged(deviceID: UUID)
}

protocol RealtimeClient {
    func connect(userID: UUID)
    func disconnect()
    func onEvent(_ handler: @escaping (RealtimeEvent) -> Void)
}
