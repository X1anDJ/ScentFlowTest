//
//  RemoteAPI.swift
//  Protocol surface for future backend (REST/GraphQL); stubbed for now.
//
//
//  Created by Dajun Xian on 10/10/25.
//
import Foundation

struct RemoteUser: Equatable, Codable {
    let id: UUID
    let displayName: String
}

protocol RemoteAPI {
    // Auth
    func signInWithApple(idToken: String) async throws -> RemoteUser

    // Templates
    func fetchTemplates() async throws -> [ScentsTemplate]
    func upsertTemplate(_ t: ScentsTemplate) async throws -> ScentsTemplate
    func deleteTemplate(id: UUID) async throws

    // Devices & State
    func fetchDevices() async throws -> [Device]
    func setDesiredState(deviceID: UUID, command: ControlCommand) async throws
}
