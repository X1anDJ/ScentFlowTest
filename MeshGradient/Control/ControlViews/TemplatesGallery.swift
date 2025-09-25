import SwiftUI

struct TemplatesGallery: View {
    let names: [String]
    let colorDict: [String: Color]
    let templates: [ColorTemplate]
    let onTapTemplate: (ColorTemplate) -> Void
    let onDeleteTemplate: (ColorTemplate) -> Void

    @State private var toDelete: ColorTemplate?

    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 14) {
//                    ForEach(templates) { t in
//                        // Tap to apply; long-press to delete
//                        Button { onTapTemplate(t) } label: {
//                            TemplatePreviewCard(
//                                template: t,
//                                names: names,
//                                colorDict: colorDict
//                            )
//                        }
//                        .buttonStyle(.plain)
//                        .simultaneousGesture(
//                            LongPressGesture(minimumDuration: 0.5)
//                                .onEnded { _ in toDelete = t }
//                        )
//                    }
//                }
//                .padding(.vertical, 4)
//            }
//            
//            Spacer()
//        }
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(templates) { t in
                    // Tap to apply; long-press to delete
                    Button { onTapTemplate(t) } label: {
                        TemplatePreviewCard(
                            template: t,
                            names: names,
                            colorDict: colorDict
                        )
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in toDelete = t }
                    )
                }
            }
//            .padding(.vertical, 4)
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
