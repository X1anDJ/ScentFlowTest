//
//  AppUser.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/18/26.
//


import Foundation
import Combine

struct AppUser: Equatable {
    let name: String
    let id: String
    let memberLevel: String
    let countryCode: String
    let phoneNumber: String
}

final class AuthSession: ObservableObject {
    static let testCountryCode: SupportedCountryCode = .cn
    static let testPhoneNumber = "16666666666"
    static let testPassword = "0000"
    static let testSMSCode = "0000"

    @Published private(set) var currentUser: AppUser?

    var isLoggedIn: Bool {
        currentUser != nil
    }

    func loginWithPassword(
        countryCode: SupportedCountryCode,
        phoneNumber: String,
        password: String
    ) -> Bool {
        guard matchesTestAccount(countryCode: countryCode, phoneNumber: phoneNumber),
              password == Self.testPassword
        else { return false }

        currentUser = makeTestUser(countryCode: countryCode, phoneNumber: phoneNumber)
        return true
    }

    func loginWithSMS(
        countryCode: SupportedCountryCode,
        phoneNumber: String,
        code: String
    ) -> Bool {
        guard matchesTestAccount(countryCode: countryCode, phoneNumber: phoneNumber),
              code == Self.testSMSCode
        else { return false }

        currentUser = makeTestUser(countryCode: countryCode, phoneNumber: phoneNumber)
        return true
    }

    func logout() {
        currentUser = nil
    }

    private func matchesTestAccount(
        countryCode: SupportedCountryCode,
        phoneNumber: String
    ) -> Bool {
        countryCode == Self.testCountryCode && phoneNumber == Self.testPhoneNumber
    }

    private func makeTestUser(
        countryCode: SupportedCountryCode,
        phoneNumber: String
    ) -> AppUser {
        AppUser(
            name: "Dajun X",
            id: "8294567",
            memberLevel: "Gold",
            countryCode: countryCode.displayName,
            phoneNumber: phoneNumber
        )
    }
}

extension AuthSession {
    static var previewLoggedIn: AuthSession {
        let session = AuthSession()
        _ = session.loginWithPassword(
            countryCode: .cn,
            phoneNumber: Self.testPhoneNumber,
            password: Self.testPassword
        )
        return session
    }
}