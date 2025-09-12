//
//  DevicePickerSheet.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/11/25.
//


import SwiftUI

/// Simple picker to switch between devices (current + mock).
struct DevicePickerSheet: View {
    @ObservedObject var store: DevicesStore
    let onSelected: (DeviceProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.devices) { device in
                    Button {
                        store.select(device.id)
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
                            if store.selectedID == device.id {
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
