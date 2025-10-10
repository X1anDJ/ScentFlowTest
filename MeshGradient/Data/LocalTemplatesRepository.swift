//
//  LocalTemplatesRepository.swift
//  Simple UserDefaults-backed templates store you can later swap for SwiftData.
//
//  Created by Dajun Xian on 10/10/25.
//

import Foundation


protocol TemplatesRepository {
    func loadAll() async -> [ScentsTemplate]
    func saveAll(_ templates: [ScentsTemplate]) async
}

struct LocalTemplatesRepository: TemplatesRepository {
    private let key = "templates"

    func loadAll() async -> [ScentsTemplate] {
        await Task.detached(priority: .utility) {
            guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
            return (try? JSONDecoder().decode([ScentsTemplate].self, from: data)) ?? []
        }.value
    }

    func saveAll(_ templates: [ScentsTemplate]) async {
        await Task.detached(priority: .utility) {
            let data = try? JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: key)
        }.value
    }
}
