import Foundation

protocol TemplatesRepository {
    func load() throws -> [ColorTemplate]
    func save(_ templates: [ColorTemplate]) throws
}

/// Simple persistence using UserDefaults and JSON (string-based ColorTemplate).
struct UserDefaultsTemplatesRepository: TemplatesRepository {
    private let key = "templates.v1.strings"

    func load() throws -> [ColorTemplate] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([ColorTemplate].self, from: data)
    }

    func save(_ templates: [ColorTemplate]) throws {
        let data = try JSONEncoder().encode(templates)
        UserDefaults.standard.set(data, forKey: key)
    }
}
