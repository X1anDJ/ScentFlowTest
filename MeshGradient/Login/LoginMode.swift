//
//  LoginMode.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/18/26.
//

import Foundation

enum LoginMode {
    case code
    case password

    var title: String {
        switch self {
        case .code:
            return "SMS Login"
        case .password:
            return "Password"
        }
    }

    var toggleTitle: String {
        switch self {
        case .code:
            return "Password"
        case .password:
            return "SMS Login"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .code:
            return "Get Code"
        case .password:
            return "Log In"
        }
    }
}

enum SupportedCountryCode: String, CaseIterable, Hashable {
    case us = "+1"
    case cn = "+86"

    var displayName: String {
        rawValue
    }

    var examplePhone: String {
        "Phone number"
    }

    var minDigits: Int {
        switch self {
        case .us: return 10
        case .cn: return 11
        }
    }

    var maxDigits: Int {
        switch self {
        case .us: return 10
        case .cn: return 11
        }
    }
}
