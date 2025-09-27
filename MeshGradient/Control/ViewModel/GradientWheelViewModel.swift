import SwiftUI
import Combine

actor GradientWheelBuilder {
    struct Snapshot {
        let orderedPodIDs: [UUID]
        let colorsByPodID: [UUID: Color]
        let included: Set<UUID>
        let opacities: [UUID: Double]
        let maxIntensity: Double
    }
    
    func makeStops(from s: Snapshot) -> [Color] {
        let maxI = max(0.0001, s.maxIntensity)
        let ids = s.orderedPodIDs.filter { s.included.contains($0) }
        var stops: [Color] = ids.compactMap { id in
            guard let base = s.colorsByPodID[id] else { return nil }
            let a = min(s.maxIntensity, max(0, s.opacities[id] ?? 0))
            return a < 0.01 ? nil : base.opacity(a / maxI)
        }
        if stops.count == 1 { stops.append(contentsOf: [stops[0], stops[0].opacity(0.5)]) }
        else if stops.count == 2 { stops.append(stops[0].opacity(0.5)) }
        return stops
    }
}

@MainActor
final class GradientWheelViewModel: ObservableObject {

    // MARK: - External, live inputs (device pods + power)
    @Published private(set) var orderedPodIDs: [UUID] = []
    private var colorsByPodID: [UUID: Color] = [:]
    @Published private(set) var pods: [ScentPod] = []

    /// Power state the UI binds to
    @Published private(set) var isPowerOn: Bool = true
    @Published var wheelOpacity: Double = 1.0

    @Published var fanSpeed: Double = 0.5

    // MARK: - Selection & per-pod intensity
    @Published private(set) var included: Set<UUID> = []
    @Published private(set) var opacities: [UUID: Double] = [:]
    @Published private(set) var focusedPodID: UUID?
    var canSelectMore: Bool { included.count < 6 }

    // MARK: - Output
    @Published private(set) var selectedColorsWeighted: [Color] = []

    // MARK: - Async machinery
    private var rebuildTask: Task<Void, Never>?
    private var clearTask: Task<Void, Never>?
    private let builder = GradientWheelBuilder()

    deinit { rebuildTask?.cancel(); clearTask?.cancel() }

    // MARK: - Public API
    func updateDevicePods(_ pods: [ScentPod]) {
        self.pods = pods
        orderedPodIDs = pods.map(\.id)
        colorsByPodID = Dictionary(uniqueKeysWithValues: pods.map { ($0.id, $0.color.color) })
        if isPowerOn { scheduleWheelRebuild() }
    }

    func setPower(_ on: Bool) {
        guard on != isPowerOn else { return }
        isPowerOn = on
        if on {
            clearTask?.cancel(); clearTask = nil
            scheduleWheelRebuild()
            withAnimation(.easeInOut(duration: 1.0)) { wheelOpacity = 1.0 }
        } else {
            let fade: Double = 1.0
            withAnimation(.easeInOut(duration: fade)) { wheelOpacity = 0.0 }
            clearTask?.cancel()
            clearTask = Task { [weak self] in
                guard let self else { return }
                try? await Task.sleep(nanoseconds: UInt64(fade * 1_000_000_000))
                if Task.isCancelled { return }
                await MainActor.run { self.selectedColorsWeighted = [] }
            }
        }
    }

    /// 👇 NEW: tiny helpers so your ControlsSection compiles without changes
    func togglePower() { setPower(!isPowerOn) }
    func setFanSpeed(_ v: Double) { fanSpeed = max(0, min(1, v)) }

    func applyTemplate(_ template: ScentsTemplate?, on device: Device) {
        guard let template else {
            included = []; focusedPodID = nil
            if isPowerOn { scheduleWheelRebuild() }
            return
        }
        let insertedIDs = Set(device.insertedPods.map(\.id))
        let ordered = template.scentPodIDs.filter { insertedIDs.contains($0) }.prefix(6)
        included = Set(ordered)
        focusedPodID = ordered.first
        var newOpacities = opacities
        for id in ordered where newOpacities[id] == nil {
            newOpacities[id] = AppConfig.maxIntensity * 0.5
        }
        newOpacities = newOpacities.filter { included.contains($0.key) }
        opacities = newOpacities
        if isPowerOn { scheduleWheelRebuild() }
    }

    func toggle(_ podID: UUID) {
        if included.contains(podID) {
            if focusedPodID == podID {
                included.remove(podID)
                opacities[podID] = nil
                focusedPodID = orderedPodIDs.first(where: { included.contains($0) })
            } else {
                focusedPodID = podID
            }
        } else {
            guard canSelectMore else { return }
            included.insert(podID)
            focusedPodID = podID
            opacities[podID] = opacities[podID] ?? (AppConfig.maxIntensity * 0.5)
        }
        if isPowerOn { scheduleWheelRebuild() }
    }

    func setOpacity(_ value: Double, for podID: UUID) {
        let clamped = max(0.0, min(AppConfig.maxIntensity, value))
        opacities[podID] = clamped
        if isPowerOn { scheduleWheelRebuild() }
    }

    // MARK: - Debounced rebuild
    func scheduleWheelRebuild() {
        rebuildTask?.cancel(); clearTask?.cancel()
        let snap = GradientWheelBuilder.Snapshot(
            orderedPodIDs: orderedPodIDs,
            colorsByPodID: colorsByPodID,
            included: included,
            opacities: opacities,
            maxIntensity: AppConfig.maxIntensity
        )
        rebuildTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 80_000_000)
            let stops = await self?.builder.makeStops(from: snap) ?? []
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self else { return }
                withAnimation(.easeInOut(duration: 1.0)) {
                    self.selectedColorsWeighted = stops
                }
            }
        }
    }


    // MARK: - Snapshot I/O (bind to your CurrentSettings if desired)
    struct WheelSnapshot: Codable, Equatable {
        var included: Set<UUID>
        var opacities: [UUID: Double]
        var focusedPodID: UUID?
    }

    func snapshot() -> WheelSnapshot {
        WheelSnapshot(included: included, opacities: opacities, focusedPodID: focusedPodID)
    }

    func load(from s: WheelSnapshot, powerOn: Bool) {
        included    = s.included
        opacities   = s.opacities
        focusedPodID = s.focusedPodID
        setPower(powerOn)

        if !powerOn || included.isEmpty {
            selectedColorsWeighted = []
            wheelOpacity = powerOn ? 1.0 : 0.0
            rebuildTask?.cancel()
            clearTask?.cancel()
        } else {
            wheelOpacity = 1.0
            scheduleWheelRebuild()
        }
    }
}


extension GradientWheelViewModel {
    func exportSettings() -> WheelSettings {
        WheelSettings(isPowerOn: isPowerOn,
                      fanSpeed: fanSpeed,
                      wheel: snapshot())
    }

    func load(from s: WheelSettings) {
        // load wheel sub-state
        load(from: s.wheel, powerOn: s.isPowerOn)
        // fan
        setFanSpeed(s.fanSpeed)
    }
}
