//
//  Overlays.swift
//  MeshGradient
//
//  Layout: dark outer mask, centered rounded-rect “scan window”,
//  then (outside the rect) a white instruction label and flashlight button.
//

import SwiftUI
import UIKit
import AVFoundation

struct ReticleOverlay: View {
    var instruction: String
    var isTorchOn: Bool
    var onToggleTorch: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let boxW = min(proxy.size.width * 0.82, 360)
            let boxH = min(proxy.size.width * 0.58, 260)
            let corner: CGFloat = 18
            let spacingBelowRect: CGFloat = 60

            ZStack {
                // 1) Dark outer mask with a punched-out hole
                Color.black.opacity(0.72)
                    .ignoresSafeArea()
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .frame(width: boxW, height: boxH)
                            .blendMode(.destinationOut)
                    )
                    .compositingGroup()

                // 2) White border for the scan rectangle
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(.white.opacity(0.95), lineWidth: 2)
                    .frame(width: boxW, height: boxH)

                // 3) OUTSIDE content: label + torch button stacked UNDER the rectangle
                VStack(spacing: 10) {
                    Text(instruction)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)

                    Button(action: onToggleTorch) {
                        Label(isTorchOn ? "Flashlight On" : "Flashlight Off",
                              systemImage: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.white)
                        
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(isTorchOn ? "Turn torch off" : "Turn torch on")
                    .controlSize(.large)
                }
                .frame(width: boxW)
                // Position this stack just below the rectangle's bottom edge
                .offset(y: (boxH / 2) + spacingBelowRect)
                // Keep it from going off-screen bottom by limiting max height
                .padding(.bottom, 20)
            }
        }
    }
}

struct ScannedBanner: View {
    let code: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
            Text(code)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .font(.subheadline.monospaced())
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 8)
    }
}

/// (If you need blur elsewhere)
struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemThinMaterialDark
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
