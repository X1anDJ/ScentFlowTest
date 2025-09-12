//
//  ScannerSheet.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//


import SwiftUI

/// Placeholder scanner screen. You’ll wire up AVFoundation / Vision later.
struct ScannerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Backdrop
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .glassEffect(.clear)
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                }

                VStack(spacing: 16) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 60, weight: .regular))
                    Text("Add a Device")
                        .font(.title3).bold()
                    Text("Point the camera at your device’s barcode or QR code to pair it.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(24)
            }
            .padding()
            .navigationTitle("Scan Barcode")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
