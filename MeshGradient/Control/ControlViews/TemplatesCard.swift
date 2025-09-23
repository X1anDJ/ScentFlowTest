import SwiftUI

struct TemplatesCard: View {
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
        CardContainer(title: "Templates") {
            // trailing actions
            HStack(spacing: 8) {
                Button {
                    // Pre-fill with a sensible default; user can edit in the alert
                    newTemplateName = "Mix \(templates.count + 1)"
                    showingNameAlert = true
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
        // Native SwiftUI alert with a TextField for the name (iOS 16+)
        .alert("Save Template", isPresented: $showingNameAlert) {
            TextField("Template name", text: $newTemplateName)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)

            Button("Save") {
                saveCurrentTemplate(named: newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines))
            }
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
