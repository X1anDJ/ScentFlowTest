//
//  ColorRow.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/12/25.
//


import SwiftUI

/// Reusable scent intensity row used by both Controls and Customize Pod.
struct ColorRow: View {
    let name: String
    let color: Color
    /// 0...1 displayed percent
    let displayed: Double
    let onChangeDisplayed: (Double) -> Void
    let onFocusOrToggle: () -> Void
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onFocusOrToggle) {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            

            Text(name + " Scent")
                .lineLimit(1)
                .font(.footnote)
                .frame(width: 90, alignment: .leading)
                

            Slider(value: Binding(
                get: { displayed },
                set: { onChangeDisplayed($0) }
            ), in: 0...1)
            .sliderTintGray()
            
            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "multiply.circle.fill")
                        .symbolRenderingMode(.palette)
                        .font(.title3)
                        .accessibilityLabel("Remove \(name)")
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }

//            Text("\(Int(displayed * 100))%")
//                .font(.footnote.monospacedDigit())
//                .frame(width: 44, alignment: .trailing)
//                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
