//
//  TemplatesService.swift
//  Owns templates in memory, persists locally, and (later) syncs with backend.
//  - Stays @MainActor for UI safety
//  - Moves I/O off the main thread with Task.detached
//  - Persists activeTemplateID in UserDefaults
//

import Foundation
import Combine

@MainActor
final class TemplatesService: ObservableObject {
    @Published private(set) var templates: [ScentsTemplate] = []
    @Published private(set) var activeTemplateID: UUID?

    private let local: TemplatesRepository
    var remote: RemoteAPI? // future

    // Key for persisting active selection
    private let activeKey = "templates_active_id_v1"

    init(local: TemplatesRepository) {
        self.local = local
        // Restore active selection eagerly (fast, tiny read)
        if let s = UserDefaults.standard.string(forKey: activeKey) {
            activeTemplateID = UUID(uuidString: s)
        }
    }

    /// Loads templates from local storage into memory (off the main thread).
    func load() {
        Task {
            let list = await Task.detached(priority: .utility) { await self.local.loadAll() }.value
            // back on main actor:
            self.templates = list
            if let id = self.activeTemplateID,
               list.first(where: { $0.id == id }) == nil {
                self.activeTemplateID = nil
                self.persistActiveID()
            }
        }
    }

    /// Returns the currently active template, if any.
    var activeTemplate: ScentsTemplate? {
        guard let id = activeTemplateID else { return nil }
        return templates.first { $0.id == id }
    }

    /// Sets the active template ID and persists state locally.
    func setActiveTemplateID(_ id: UUID?) {
        activeTemplateID = id
        persistActiveID()
    }

    /// Adds a new template, persists, and (optionally) sets it active.
    func add(_ t: ScentsTemplate, setActive: Bool = true) {
        templates.append(t)
        if setActive { activeTemplateID = t.id; persistActiveID() }
        persistTemplates()
    }

    /// Updates a template by ID; no-op if not found.
    func update(_ t: ScentsTemplate) {
        guard let i = templates.firstIndex(where: { $0.id == t.id }) else { return }
        templates[i] = t
        persistTemplates()
    }

    /// Removes a template and clears active if it was active.
    func remove(id: UUID) {
        templates.removeAll { $0.id == id }
        if activeTemplateID == id {
            activeTemplateID = nil
            persistActiveID()
        }
        persistTemplates()
    }

    // MARK: - Persistence (off main)

    private func persistTemplates() {
        let snapshot = templates
        Task.detached(priority: .utility) {
            await self.local.saveAll(snapshot)
        }
    }

    private func persistActiveID() {
        let s = activeTemplateID?.uuidString
        // This write is tiny; OK on main, but you can also detach if you prefer.
        UserDefaults.standard.set(s, forKey: activeKey)
    }
}
