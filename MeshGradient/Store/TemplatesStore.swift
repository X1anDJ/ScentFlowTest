//
//  TemplatesStore.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/24/25.
//


// TemplatesStore.swift
import SwiftUI
import Combine

@MainActor
final class TemplatesStore: ObservableObject {
    @Published private(set) var templates: [ColorTemplate] = []
    private let repo: TemplatesRepository

    init(repo: TemplatesRepository = UserDefaultsTemplatesRepository()) {
        self.repo = repo
        load()
    }

    func load() {
        do { templates = try repo.load() } catch { templates = [] }
    }

    func add(_ t: ColorTemplate) {
        templates.insert(t, at: 0)
        save()
    }

    func remove(_ t: ColorTemplate) {
        templates.removeAll { $0.id == t.id }
        save()
    }

    private func save() {
        try? repo.save(templates)
    }
}
