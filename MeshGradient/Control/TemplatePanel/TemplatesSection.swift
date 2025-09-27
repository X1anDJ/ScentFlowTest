// TemplatesSection.swift — refactored to ScentsTemplate + VM + Device

import SwiftUI

struct TemplatesSection: View {
    // Use the new model + stores
    @ObservedObject var store: TemplatesStore
    @ObservedObject var vm: GradientWheelViewModel
    let device: Device

    @State private var showingNameAlert = false
    @State private var newTemplateName: String = ""

    var body: some View {
        VStack(spacing: 12) {

            if store.templates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        SaveTemplateCard(
                            title: "Save"
                        ) {
                            newTemplateName = "Mix \(store.templates.count + 1)"
                            showingNameAlert = true
                        }
                    }
                }
            } else {
                TemplatesGallery(
                    device: device,
                    templates: store.templates,
                    onTapTemplate: { t in
                        // Apply to wheel (intersects with device pods and rebuilds)
                        vm.applyTemplate(t, on: device)
                        // Optionally: also persist as active if you track it in settings/store
                        store.activeTemplateID = t.id
                        store.persist()
                    },
                    onDeleteTemplate: { t in
                        store.remove(id: t.id)
                    }
                )
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    newTemplateName = "Mix \(store.templates.count + 1)"
                    showingNameAlert = true
                } label: {
                    Label("Save", systemImage: "plus.circle.fill").labelStyle(.titleAndIcon)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                Spacer()
            }
            .padding(.bottom, 16)
        }
        .alert("Save Template", isPresented: $showingNameAlert) {
            TextField("Template name", text: $newTemplateName)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)

            Button("Save") {
                let name = newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                saveCurrentTemplate(named: name)
                newTemplateName = ""
            }

            Button("Cancel", role: .cancel) {
                newTemplateName = ""
            }
        } message: {
            Text("Enter a name for this scent mix.")
        }
    }

    private func saveCurrentTemplate(named name: String) {
        // Preserve a stable, user-visible order: the device’s pod order filtered by inclusion
        let orderedIncluded = vm.pods.map(\.id).filter { vm.included.contains($0) }.prefix(6)
        guard !orderedIncluded.isEmpty else { return }

        let new = ScentsTemplate(name: name, scentPodIDs: Array(orderedIncluded))
        store.add(new)
        store.activeTemplateID = new.id
        store.persist()
    }
}
