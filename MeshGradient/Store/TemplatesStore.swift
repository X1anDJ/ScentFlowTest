// TemplatesStore.swift  — add an init that calls load()

import Foundation
import Combine

@MainActor
final class TemplatesStore: ObservableObject {
    @Published private(set) var templates: [ScentsTemplate] = []
    @Published var activeTemplateID: UUID?

    private let repo = TemplatesRepository()

    init() {
        // Always load saved templates on construction
        load()
    }

    var activeTemplate: ScentsTemplate? {
        guard let id = activeTemplateID else { return nil }
        return templates.first { $0.id == id }
    }

    // CRUD
    func set(_ templates: [ScentsTemplate]) { self.templates = templates; persist() }
    func add(_ t: ScentsTemplate) { templates.append(t); persist() }
    func update(_ t: ScentsTemplate) {
        guard let i = templates.firstIndex(where: { $0.id == t.id }) else { return }
        templates[i] = t; persist()
    }
    func remove(id: UUID) {
        templates.removeAll { $0.id == id }
        if activeTemplateID == id { activeTemplateID = nil }
        persist()
    }

    // Persistence
    func load() { templates = (try? repo.load()) ?? [] }
    func persist() { try? repo.save(templates) }

    // Mock seeding (call only after load if you want defaults)
    func seedMockIfNeeded(using device: Device) {
        guard templates.isEmpty else { return }
        let ids = Array(device.insertedPods.prefix(3)).map(\.id)
        let t = ScentsTemplate(name: "Citrus Breeze", scentPodIDs: ids)
        set([t])
        activeTemplateID = t.id
        persist()
    }
}
