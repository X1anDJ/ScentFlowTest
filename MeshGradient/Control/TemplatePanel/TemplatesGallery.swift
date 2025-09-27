// TemplatesGallery.swift — refactored to ScentsTemplate + Device + new card

import SwiftUI

struct TemplatesGallery: View {
    let device: Device
    let templates: [ScentsTemplate]
    let onTapTemplate: (ScentsTemplate) -> Void
    let onDeleteTemplate: (ScentsTemplate) -> Void

    @State private var toDelete: ScentsTemplate?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(templates) { t in
                    // Tap to apply; long-press to delete
                    Button { onTapTemplate(t) } label: {
                        TemplatePreviewCard(template: t, device: device)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in toDelete = t }
                    )
                }
            }
        }
        .confirmationDialog(
            "Delete this template?",
            isPresented: Binding(
                get: { toDelete != nil },
                set: { if !$0 { toDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let t = toDelete {
                Button("Delete \"\(t.name)\"", role: .destructive) {
                    onDeleteTemplate(t)
                    toDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { toDelete = nil }
        } message: {
            if let t = toDelete {
                Text("This will remove \"\(t.name)\" permanently.")
            }
        }
    }
}
