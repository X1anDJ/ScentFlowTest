//
//  TemplatesSection.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/24/25.
//


import SwiftUI
// TemplatesSection.swift (signature)
struct TemplatesSection: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let opacities: [String: Double]
    let onApplyTemplate: (_ included: Set<String>, _ opacities: [String: Double]) -> Void

    @ObservedObject var store: TemplatesStore  // <-- add this

    @State private var showingNameAlert = false
    @State private var newTemplateName: String = ""

    var body: some View {
        VStack(spacing: 12) {
//            HStack {
//                Spacer()
//
//                Button {
//                    newTemplateName = "Mix \(store.templates.count + 1)"
//                    showingNameAlert = true
//                } label: {
//                    Label("Save", systemImage: "plus.circle.fill").labelStyle(.titleAndIcon)
//                }
//                .buttonStyle(.glass)
//                .controlSize(.regular)
//                
//                Spacer()
//            }

            if store.templates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        SaveTemplateCard(
                            title: "Save",
                           // subtitle: "Capture current mix"
                        ) {
                            // Same behavior as your Save button
                            newTemplateName = "Mix \(store.templates.count + 1)"
                            showingNameAlert = true
                        }
                    }
//                    .padding(.vertical, 2)
//                    .padding(.top, 2)
                }
            } else {
                TemplatesGallery(
                    names: names,
                    colorDict: colorDict,
                    templates: store.templates,
                    onTapTemplate: { t in onApplyTemplate(t.included, t.opacities) },
                    onDeleteTemplate: { t in store.remove(t) }
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
                newTemplateName = "" // optional: clear after saving
            }

            Button("Cancel", role: .cancel) {
                newTemplateName = "" // optional: clear on cancel
            }
        } message: {
            Text("Enter a name for this scent mix.")
        }

    }

    private func saveCurrentTemplate(named name: String) {
        guard !name.isEmpty else { return }
        let new = ColorTemplate(name: name, included: included, opacities: opacities)
        store.add(new)
    }
}
