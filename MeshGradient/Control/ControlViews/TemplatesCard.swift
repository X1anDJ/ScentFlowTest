import SwiftUI

/// Wrapper that matches your original ContentView call site:
/// TemplatesCard(
///   names: [String],
///   colorDict: [String: Color],
///   included: Set<String>,
///   opacities: [String: Double],
///   onApplyTemplate: (Set<String>, [String: Double]) -> Void
/// )
struct TemplatesCard: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>                 // current mix
    let opacities: [String: Double]           // current mix
    let onApplyTemplate: (_ included: Set<String>, _ opacities: [String: Double]) -> Void

    // In-memory list of saved templates (string-based model to match your ColorTemplate.swift)
    @State private var templates: [ColorTemplate] = []

    var body: some View {
        CardContainer(title: "Templates") {
            // trailing actions
            HStack(spacing: 8) {
                Button {
                    saveCurrentTemplate()
                } label: {
                    Label("Save", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
        } content: {
            if templates.isEmpty {
                Text("No templates yet. Tap **Save** to capture the current mix.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Uses your existing TemplatesGallery from ColorTemplate.swift
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
        }
    }

    private func saveCurrentTemplate() {
        // Give it a simple default name based on count
        let new = ColorTemplate(
            name: "Mix \(templates.count + 1)",
            included: included,
            opacities: opacities
        )
        templates.insert(new, at: 0)
    }
}
