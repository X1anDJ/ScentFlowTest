// CurrentSettings.swift — now app-wide only (no power/fan)

import Foundation
import Combine

public struct CurrentSettings: Codable, Equatable {
    public var activeTemplateID: UUID? = nil
    // Deprecated in favor of per-device settings:
    // public var isPowerOn: Bool = true
    // public var fanLevel: Int = 1
}

@MainActor
final class CurrentSettingsStore: ObservableObject {
    @Published var settings = CurrentSettings()
    private let key = "current_settings"

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let s = try? JSONDecoder().decode(CurrentSettings.self, from: data) { settings = s }
    }
    func persist() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
