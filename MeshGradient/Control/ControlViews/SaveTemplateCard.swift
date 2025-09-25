//
//  SaveTemplateCard.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//


import SwiftUI

struct SaveTemplateCard: View {
    var title: String = "Save"
    var subtitle: String = "Capture current mix"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Art area – sized like TemplatePreviewCard's 80×80 render
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)       // no gradient mesh, just subtle surface
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 16, style: .continuous)
//                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
//                        )

                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .opacity(0.95)
                }
                .frame(width: 80, height: 80)

                Text(title)
                    .font(.footnote)
                    .lineLimit(1)
                    .frame(width: 90)
                    .multilineTextAlignment(.center)
                    .opacity(1)
                
//                // Label — matches the gallery label width/size
//                VStack(spacing: 2) {
//                    
////
////                    Text(subtitle)
////                        .font(.caption2)
////                        .foregroundStyle(.secondary)
////                        .lineLimit(2)
////                        .multilineTextAlignment(.center)
//                }
//                .frame(width: 90)
            }
            .padding(10)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
    }
}
