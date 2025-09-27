// ScentPodsRow.swift  (ID-based, no colorDict or name arrays)

import SwiftUI

struct ScentPodsRow: View {
    let pods: [ScentPod]
    let includedIDs: Set<UUID>
    let focusedID: UUID?
    let canSelectMore: Bool
    let onTap: (UUID) -> Void

    // Visual constants
    private let diameter: CGFloat = 28
    private let ringWidth: CGFloat = 3
    private let focusScale: CGFloat = 1.1

    var body: some View {
        GeometryReader { geo in
            let count = pods.count
            let totalChipWidth = CGFloat(count) * diameter
            let spacing = count > 1
                ? (geo.size.width - totalChipWidth) / CGFloat(max(1, count - 1))
                : 0

            HStack(spacing: spacing) {
                ForEach(pods, id: \.id) { pod in
                    chip(for: pod)
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
    private func chip(for pod: ScentPod) -> some View {
        let color = pod.color.color
        let isAdded = includedIDs.contains(pod.id)
        let isFocused = (focusedID == pod.id)

        Button { onTap(pod.id) } label: {
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
        .accessibilityLabel(Text("\(pod.name) \(isAdded ? "added" : "not added")"))
        .accessibilityHint(Text(isAdded ? "Tap to focus, tap again to remove" : "Tap to add"))
    }
}
