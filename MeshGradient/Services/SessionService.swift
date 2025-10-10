//
//  SessionService.swift
//  MeshGradient
//
//  Created by Dajun Xian on 10/10/25.
//
//  Tracks whether the user is a guest or signed in,
//  and exposes a simple API to switch states.
//

import Foundation
import Combine

@MainActor
final class SessionService: ObservableObject {
    enum State: Equatable {
        case guest
        case signedIn(User)
    }

    struct User: Equatable, Codable {
        let id: UUID
        let displayName: String
    }

    @Published private(set) var state: State = .guest

    /// Signs in with an already-validated identity (future: Sign in with Apple flow).
    func signIn(displayName: String) {
        // In a real app, exchange Apple ID token with backend and get a canonical user.
        let user = User(id: UUID(), displayName: displayName)
        state = .signedIn(user)
    }

    /// Signs out to guest mode (keeps local data; you could also clear).
    func signOut() {
        state = .guest
    }
}
