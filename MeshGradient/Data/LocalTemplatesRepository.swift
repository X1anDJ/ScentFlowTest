//
//  LocalTemplatesRepository.swift
//  Simple UserDefaults-backed templates store you can later swap for SwiftData.
//
//  Created by Dajun Xian on 10/10/25.
//

import Foundation

protocol TemplatesRepository {
    /// Returns all templates from local storage.
    func loadAll() -> [ScentsTemplate]
    /// Persists the entire templates array atomically.
    func saveAll(_ templates: [ScentsTemplate])
}

struct LocalTemplatesRepository: TemplatesRepository {
    private let key = "templates_v2"        // versioned key (safe to evolve)

    func loadAll() -> [ScentsTemplate] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ScentsTemplate].self, from: data)) ?? []
    }

    func saveAll(_ templates: [ScentsTemplate]) {
        let data = try? JSONEncoder().encode(templates)
        UserDefaults.standard.set(data, forKey: key)
    }
}
