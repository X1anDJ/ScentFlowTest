//
//  SyncEngine.swift
//  MeshGradient
//
//  Created by Dajun Xian on 10/10/25.
//
//  Coordinates two-way sync with backend once signed in. Today it's a safe no-op,
//  but the surface is ready for Phase 1/2 work.
//

import Foundation

@MainActor
final class SyncEngine {
    private var user: SessionService.User?

    /// Starts sync for a signed-in user. You can wire RemoteAPI/Realtime here.
    func start(user: SessionService.User, templates: TemplatesService, devices: DevicesService) {
        self.user = user
        // Phase 1 idea:
        // 1) Fetch remote templates/devices.
        // 2) Merge with local (last-write-wins).
        // 3) Push local-only records to remote.
        // 4) Subscribe to realtime updates and apply them to services.
    }

    /// Stops sync and tears down realtime connections.
    func stop() {
        user = nil
        // Close sockets, cancel tasks, etc.
    }
}
