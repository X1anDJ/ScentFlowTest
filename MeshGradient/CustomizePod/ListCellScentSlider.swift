//
//  ListCellScentSlider.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/27/25.
//


import SwiftUI
 
struct ListCellScentSlider: View {
    let name: String
    let color: Color
    /// 0...1 displayed percent
    let displayed: Double
    let onChangeDisplayed: (Double) -> Void
    var onFocusOrToggle: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let onFocusOrToggle {
                Button(action: onFocusOrToggle) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Focus \(name)")
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }

            Text(name)
                .lineLimit(1)
                .font(.footnote)
                .frame(width: 100, alignment: .leading)

            Slider(
                value: Binding(
                    get: { displayed },
                    set: { onChangeDisplayed($0) }
                ),
                in: 0...1
            )
            .sliderTintGray()

            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "multiply.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
                .accessibilityLabel("Remove \(name)")
            }
        }
 
        .listRowBackground(Color.clear)
    }
}

/// The trailing "Add Scent" row that appears as the last cell while activeColors < 6.
struct AddScentListRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Image(systemName: "plus")
                    .font(.headline)
                
                Text("Add Scent")
                    .font(.subheadline).fontWeight(.semibold)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(.thickMaterial )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.7)
                .blendMode(.overlay)
        )
        .accessibilityLabel("Add Scent")
    }
}
