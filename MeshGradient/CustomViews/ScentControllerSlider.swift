//
//  ScentControllerSlider.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//


//
//  ScentControllerExpanded.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//


//
//  ColorRow.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/12/25.
//


import SwiftUI

/// Reusable scent intensity row used by both Controls and Customize Pod.
struct ScentControllerSlider: View {
    let name: String
    let color: Color
    /// 0...1 displayed percent
    let displayed: Double
    let onChangeDisplayed: (Double) -> Void
    var onFocusOrToggle: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let onFocusOrToggle {    // only show button if closure provided
                Button(action: onFocusOrToggle) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            
            

            Text(name )
                .lineLimit(1)
                .font(.footnote)
                .frame(width: 100, alignment: .leading)
                

            Slider(value: Binding(
                get: { displayed },
                set: { onChangeDisplayed($0) }
            ), in: 0...1)
            .sliderTintGray()
            
            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "multiply.circle.fill")
                        //.symbolRenderingMode(.palette)
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
        .padding(.vertical, 6)
//        .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
