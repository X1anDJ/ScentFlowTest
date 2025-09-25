//
//  TemplatesSection.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/24/25.
//


import SwiftUI

// MARK: - Templates content (no outer CardContainer)
struct TemplatesSection: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>                 // current mix
    let opacities: [String: Double]           // current mix
    let onApplyTemplate: (_ included: Set<String>, _ opacities: [String: Double]) -> Void

    @State private var templates: [ColorTemplate] = []

    // Alert state
    @State private var showingNameAlert = false
    @State private var newTemplateName: String = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Spacer()
                Button {
                    newTemplateName = "Mix \(templates.count + 1)"
                    showingNameAlert = true
                } label: {
                    Label("Save", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }

            if templates.isEmpty {
                Text("No templates yet. Tap **Save** to capture the current mix.")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                TemplatesGallery(
                    names: names,
                    colorDict: colorDict,
                    templates: templates,
                    onTapTemplate: { t in
                        onApplyTemplate(t.included, t.opacities)
                    },
                    onDeleteTemplate: { t in
                        templates.removeAll { $0.id == t.id }
                    }
                )
            }
            
            Spacer()
        }
        .alert("Save Template", isPresented: $showingNameAlert) {
            TextField("Template name", text: $newTemplateName)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)

            Button("Save") {
                saveCurrentTemplate(named: newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .buttonStyle(.glassProminent)
            .disabled(newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for this color mix.")
        }
    }

    private func saveCurrentTemplate(named name: String) {
        guard !name.isEmpty else { return }
        let new = ColorTemplate(
            name: name,
            included: included,
            opacities: opacities
        )
        templates.insert(new, at: 0)
    }
}
