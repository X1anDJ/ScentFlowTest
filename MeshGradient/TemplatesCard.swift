// TemplatesCard.swift
import SwiftUI

struct TemplatesCard: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>                 // <- current mix passed in
    let opacities: [String: Double]           // <- current mix passed in
    let onApplyTemplate: (_ included: Set<String>, _ opacities: [String: Double]) -> Void

    @State private var templates: [ColorTemplate] = []
    @State private var showingSaveSheet = false
    @State private var newTemplateName = ""

    var body: some View {
        CardContainer(title: "Templates", trailing: saveButton) {
            if templates.isEmpty {
                Text("No templates yet. Tap Save to add your current mix.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TemplatesGallery(
                    names: names,
                    colorDict: colorDict,
                    templates: templates,
                    onTapTemplate: { template in
                        onApplyTemplate(template.included, template.opacities)
                    },
                    onDeleteTemplate: { template in
                        templates.removeAll { $0.id == template.id }
                    }
                )
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveTemplateSheet(
                name: $newTemplateName,
                onCancel: { showingSaveSheet = false },
                onSave: {
                    let tmpl = ColorTemplate(
                        name: newTemplateName.isEmpty ? "Untitled" : newTemplateName,
                        included: included,
                        opacities: opacities
                    )
                    templates.append(tmpl)
                    newTemplateName = ""
                    showingSaveSheet = false
                }
            )
            .presentationDetents([.height(200)])
        }
    }

    // MARK: - Save current mix

    private var saveButton: some View {
        Button {
            showingSaveSheet = true
        } label: {
            Label("Save", systemImage: "tray.and.arrow.down")
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Save current mix as template")
    }
}

// A tiny sheet to name a template
private struct SaveTemplateSheet: View {
    @Binding var name: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(.secondary.opacity(0.25)).frame(width: 44, height: 5)
                .padding(.top, 8)

            Text("Save Template")
                .font(.headline)

            TextField("Template name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            Spacer(minLength: 12)
        }
        .padding(.bottom, 12)
    }
}
