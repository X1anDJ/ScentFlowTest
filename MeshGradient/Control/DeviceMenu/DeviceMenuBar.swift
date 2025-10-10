// DeviceMenuBar.swift  — refactored to use Device (no DeviceProfile)

import SwiftUI

struct DeviceMenuBar: View {
    @ObservedObject var devicesService: DevicesService
    @Binding var showScanner: Bool
    var onSelect: (Device) -> Void   // <- changed from DeviceProfile

    var body: some View {
        Menu {
            Section("My Devices") {
                ForEach(devicesService.devices) { device in
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
                Text(devicesService.selected?.name ?? "No device")
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
