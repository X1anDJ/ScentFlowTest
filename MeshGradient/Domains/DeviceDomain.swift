import SwiftUI
import Combine

/// Handles power/fan behaviors and eventually talks to the physical device.
@MainActor
final class DeviceDomain: ObservableObject {
    @Published var isPoweredOn: Bool = false
    @Published var fanSpeed: Double = AppConfig.defaultFanSpeed

    func togglePower() { isPoweredOn.toggle() }
    func setFanSpeed(_ value: Double) {
        fanSpeed = min(AppConfig.fanRange.upperBound, max(AppConfig.fanRange.lowerBound, value))
    }
}
