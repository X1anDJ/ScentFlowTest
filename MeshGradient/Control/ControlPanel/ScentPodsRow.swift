//
//  ScentPodsRow.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/25/25.
//


import SwiftUI

struct ScentPodsRow: View {
    let names: [String]
    let colorDict: [String: Color]
    let included: Set<String>
    let focusedName: String?
    let canSelectMore: Bool
    let onTap: (String) -> Void

    // Visual constants
    private let diameter: CGFloat = 28
    private let ringWidth: CGFloat = 3
    private let focusScale: CGFloat = 1.1

    var body: some View {
        GeometryReader { geo in
            let count = names.count
            let totalChipWidth = CGFloat(count) * diameter
            let spacing = count > 1
                ? (geo.size.width - totalChipWidth) / CGFloat(count - 1)
                : 0

            HStack(spacing: spacing) {
                ForEach(names, id: \.self) { name in
                    chip(for: name)
                        .frame(width: diameter, height: diameter)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .frame(maxWidth: .infinity, minHeight: diameter, idealHeight: diameter)
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func chip(for name: String) -> some View {
        let color = colorDict[name] ?? .gray
        let isAdded = included.contains(name)
        let isFocused = focusedName == name

        Button { onTap(name) } label: {
            ZStack {
                if isAdded {
                    Circle()
                        .fill(color)
                        .overlay(
                            Circle()
                                .stroke(
                                    isFocused ? color.opacity(0.75) : color.opacity(0.25),
                                    lineWidth: isFocused ? 3 : 1
                                )
                        )
                } else {
                    Circle()
                        .stroke(color.opacity(0.95), lineWidth: ringWidth)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                                .blendMode(.overlay)
                        )

                    if !canSelectMore {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                if isFocused {
                    Circle()
                        .fill(Color.white)
                        .frame(width: diameter * 0.25, height: diameter * 0.25)
                        .shadow(color: Color.white, radius: 1, x: 0, y: 0)
                }
            }
            .scaleEffect(isFocused ? focusScale : 1.0)
            .animation(.spring(response: 0.7, dampingFraction: 0.5), value: isFocused)
            .opacity(isAdded || canSelectMore ? 1 : 0.85)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(name) \(isAdded ? "added" : "not added")"))
        .accessibilityHint(Text(isAdded ? "Tap to focus, tap again to remove" : "Tap to add"))
    }
}
