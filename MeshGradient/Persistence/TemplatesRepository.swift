import Foundation

@MainActor
final class TemplatesRepository {
    private let key = "templates"

    func save(_ templates: [ScentsTemplate]) throws {
        let data = try JSONEncoder().encode(templates)
        UserDefaults.standard.set(data, forKey: key)
    }

    func load() throws -> [ScentsTemplate] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([ScentsTemplate].self, from: data)
    }
}
