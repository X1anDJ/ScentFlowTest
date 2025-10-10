// DevicePickerSheet.swift  — refactored to use Device (no DeviceProfile)

import SwiftUI

/// Simple picker to switch between devices (current + mock).
struct DevicePickerSheet: View {
    @ObservedObject var devicesService: DevicesService
    let onSelected: (Device) -> Void   // <- changed from DeviceProfile

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(devicesService.devices) { device in
                    Button {
                        devicesService.select(device.id)
                        onSelected(device)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name).font(.body)
                                Text(device.isMock ? "Mock" : "Physical")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if devicesService.selectedID == device.id {
                                Image(systemName: "checkmark")
                                    .font(.callout.weight(.semibold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
