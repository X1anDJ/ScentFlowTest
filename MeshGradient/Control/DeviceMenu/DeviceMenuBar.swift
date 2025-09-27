// DeviceMenuBar.swift  — refactored to use Device (no DeviceProfile)

import SwiftUI

struct DeviceMenuBar: View {
    @ObservedObject var devices: DevicesStore
    @Binding var showScanner: Bool
    var onSelect: (Device) -> Void   // <- changed from DeviceProfile

    var body: some View {
        Menu {
            Section("My Devices") {
                ForEach(devices.devices) { device in
                    Button {
                        onSelect(device)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "macmini.fill")
                            Text(device.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }

            Section("Add Device") {
                Button { showScanner = true } label: {
                    Label("Add Device", systemImage: "qrcode.viewfinder")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "macmini.fill")
                Text(devices.selected?.name ?? "No device")
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
        }
        .font(.headline)
        .foregroundStyle(.secondary)
        .accessibilityLabel(Text("Device menu"))
    }
}
