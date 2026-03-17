//
//  DeviceInfoPage.swift
//  MeshGradient
//
//  Created by Dajun Xian on 3/17/26.
//


//
//  DeviceInfoPage.swift
//  MeshGradient
//

import SwiftUI

struct DeviceInfoPage: View {
    let device: Device

    private var deviceInfoItems: [DeviceInfoItem] {
        [
            .init(title: "Device name", value: device.name, isEditable: true),
            .init(title: "Firmware Version", value: "0.5"),
            .init(title: "Check update", value: "", showsChevron: true)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                podsSection
                deviceSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
//        .customTopBar(device.name)
    }
}

private extension DeviceInfoPage {
    var podsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Pods")

            if device.insertedPods.isEmpty {
                Text("No pods inserted")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(device.insertedPods) { pod in
                        DevicePodInfoRow(
                            pod: pod,
                            insertedDateText: mockInsertedDate(for: pod.id)
                        )
                    }
                }
            }
        }
    }

    var deviceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Device")

            VStack(spacing: 1) {
                ForEach(deviceInfoItems) { item in
                    DeviceInfoRow(item: item)
                }
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(.white)
    }

    func mockInsertedDate(for id: UUID) -> String {
        // Temporary UI-only mock until API/model provides insertedAt
        let samples = [
            "2025-09-12",
            "2025-09-18",
            "2025-09-23",
            "2025-09-27",
            "2025-10-01",
            "2025-10-04"
        ]
        let index = abs(id.uuidString.hashValue) % samples.count
        return samples[index]
    }
}

// MARK: - Rows

private struct DevicePodInfoRow: View {
    let pod: ScentPod
    let insertedDateText: String

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(pod.color.color)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 6) {
                Text(pod.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)

                Text("Inserted date: \(insertedDateText)")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer(minLength: 0)

            Text(pod.level.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(pod.level.tintColor)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(
                    Capsule()
                        .fill(pod.level.tintColor.opacity(0.16))
                )
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 68)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct DeviceInfoRow: View {
    let item: DeviceInfoItem

    var body: some View {
        HStack(spacing: 12) {
            Text(item.title)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.72))

            Spacer(minLength: 0)

            if !item.value.isEmpty {
                Text(item.value)
                    .font(.system(size: 16, weight: item.isEditable ? .medium : .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
            }

            if item.isEditable {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }

            if item.showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.white.opacity(0.02))
    }
}

// MARK: - Models

private struct DeviceInfoItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    var isEditable: Bool = false
    var showsChevron: Bool = false
}
