//
//  ScentControllerSlider.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//


import SwiftUI

struct ScentControllerSlider: View {
    let name: String
    let color: Color
    /// 0...1 displayed percent
    let displayed: Double
    let onChangeDisplayed: (Double) -> Void
    var onFocusOrToggle: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    // NEW
    var showsPercentage: Bool = false
    var isDimmed: Bool = false

    var body: some View {
        HStack(spacing: 8) {
//            if let onFocusOrToggle {
//                Button(action: onFocusOrToggle) {
//                    Circle()
//                        .fill(color)
//                        .frame(width: 8, height: 8)
//                }
//                .buttonStyle(.plain)
//            } else {
//                Circle()
//                    .fill(color)
//                    .frame(width: 8, height: 8)
//            }

            Text(name)
                .lineLimit(1)
                .font(.footnote)
                .frame(width: 100, alignment: .leading)
                .foregroundStyle(isDimmed ? .secondary : .primary)

            PodIntensitySlider(
                value: Binding(
                    get: { displayed },
                    set: { onChangeDisplayed($0) }
                ),
                color: color,
                isDimmed: isDimmed
            )

            if showsPercentage {
                Text("\(Int(displayed * 100))%")
                    .font(.footnote.monospacedDigit())
                    .frame(width: 44, alignment: .trailing)
                    .foregroundStyle(.secondary)
            }

            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "multiply.circle.fill")
                        .font(.title3)
                        .accessibilityLabel("Remove \(name)")
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
        }
        .padding(.vertical, 0)
        .opacity(isDimmed ? 0.75 : 1.0)
    }
}
