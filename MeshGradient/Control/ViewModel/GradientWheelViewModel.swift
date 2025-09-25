import SwiftUI
import Combine

// MARK: - Off-main builder (pure CPU work here)
actor GradientWheelBuilder {
    struct Snapshot {
        let canonicalOrder: [String]
        let colorDict: [String: Color]
        let included: Set<String>
        let opacities: [String: Double]
        let maxIntensity: Double
    }

    func makeStops(from s: Snapshot) -> [Color] {
        let maxI = max(0.0001, s.maxIntensity)
        let names = s.canonicalOrder.filter { s.included.contains($0) }
        var stops: [Color] = names.compactMap { n in
            guard let base = s.colorDict[n] else { return nil }
            let a = min(s.maxIntensity, max(0, s.opacities[n] ?? 0))
            return a < 0.01 ? nil : base.opacity(a / maxI)
        }

        // Ensure visually rich mesh with at least 3 stops
        if stops.count == 1 {
            stops.append(contentsOf: [stops[0], stops[0].opacity(0.5)])
        } else if stops.count == 2 {
            stops.append(stops[0].opacity(0.5))
        }
        return stops
    }
}

@MainActor
final class GradientWheelViewModel: ObservableObject {
    // MARK: - Device (parent controls)
    @Published var isPowerOn: Bool = true
    @Published var fanSpeed: Double = 0.5   // reserved for later use
    @Published var wheelOpacity: Double = 1.0
    
    func togglePower() {
        let turningOn = !isPowerOn
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isPowerOn = turningOn
        }

        if turningOn {
            clearTask?.cancel()
            clearTask = nil
            
            scheduleWheelRebuild()
            withAnimation(.easeInOut(duration: 1.0)) {
                wheelOpacity = 1.0
            }
        } else {
            let fadeDuration: Double = 1.0
            withAnimation(.easeInOut(duration: fadeDuration)) {
                wheelOpacity = 0.0
            }
            clearTask?.cancel()
            clearTask = Task { [weak self] in
                guard let self else { return }
                try? await Task.sleep(nanoseconds: UInt64(fadeDuration * 1_000_000_000))
                if Task.isCancelled { return }
                await MainActor.run {
                    self.selectedColorsWeighted = []
                }
            }
        }
    }



    func setFanSpeed(_ v: Double) {
        fanSpeed = max(0, min(1, v))
        // If fan speed influences the gradient, coalesce work:
        // scheduleWheelRebuild(debounceMillis: 80)
    }

    // MARK: - Scents (existing)
    @Published var colorDict: [String: Color] = [
        "Red": .red,
        "Orange": .orange,
        "Yellow": .yellow,
        "Green": .green,
        "Cyan": .cyan,
        "Blue": .blue,
        "Violet": .purple
    ]

    let canonicalOrder = ["Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Violet"]

    // selected names (max 6), per-scent intensity, and focus
    @Published var included: Set<String> = []
    @Published var opacities: [String: Double] = [:]
    @Published var focusedName: String?

    var canSelectMore: Bool { included.count < 6 }

    // MARK: - Async wheel output (now stored + published)
    @Published private(set) var selectedColorsWeighted: [Color] = []

    // MARK: - Private async machinery
    private var rebuildTask: Task<Void, Never>?
    private var clearTask: Task<Void, Never>?
    private let builder = GradientWheelBuilder()

    deinit {
        rebuildTask?.cancel()
        clearTask?.cancel()
    }

    // Debounced off-main rebuild
    func scheduleWheelRebuild() {
        rebuildTask?.cancel()
        clearTask?.cancel()
        
        // Snapshot inputs so the worker runs on immutable data off-main
        let snap = GradientWheelBuilder.Snapshot(
            canonicalOrder: canonicalOrder,
            colorDict: colorDict,
            included: included,
            opacities: opacities,
            maxIntensity: AppConfig.maxIntensity
        )

        rebuildTask = Task { [weak self] in
            // Coalesce rapid changes (slider, taps)
       //     try? await Task.sleep(nanoseconds: UInt64(debounceMillis) * 1_000_000)
            try? await Task.sleep(nanoseconds: 80_000_000)
            // Heavy work off the main actor
            let stops = await self?.builder.makeStops(from: snap) ?? []

            if Task.isCancelled { return }

            // Publish to UI with a light animation
            await MainActor.run {
                guard let self else { return }

                withAnimation(.easeInOut(duration: 1.0)) {
                    self.selectedColorsWeighted = stops
                }
            }

        }
    }

    // MARK: - Toggle & intensity
    func toggle(_ name: String) {
        if included.contains(name) {
            if focusedName == name {
                included.remove(name)
                opacities[name] = nil
                // choose a new focus (next in canonical order) if available
                if let next = canonicalOrder.first(where: { included.contains($0) }) {
                    focusedName = next
                } else {
                    focusedName = nil
                }
            } else {
                focusedName = name
            }
        } else {
            guard canSelectMore else { return }
            included.insert(name)
            focusedName = name
            // default intensity to 50% of global cap when a scent is added
            opacities[name] = AppConfig.maxIntensity * 0.5
        }
        if isPowerOn { scheduleWheelRebuild() }
    }

    func setOpacity(_ value: Double, for name: String) {
        // clamp to global max
        let clamped = max(0.0, min(AppConfig.maxIntensity, value))
        opacities[name] = clamped
        if isPowerOn { scheduleWheelRebuild() }
    }

    // MARK: - Templates
    func applyTemplate(included newIncluded: Set<String>, opacities newOpacities: [String: Double]) {
        let limited = Array(newIncluded)
            .filter { colorDict[$0] != nil }
            .sorted { canonicalOrder.firstIndex(of: $0)! < canonicalOrder.firstIndex(of: $1)! }
            .prefix(6)

        included = Set(limited)
        focusedName = limited.first

        var out: [String: Double] = [:]
        for name in limited {
            let raw = newOpacities[name] ?? 0
            out[name] = max(0.0, min(AppConfig.maxIntensity, raw))
        }
        opacities = out

        if isPowerOn { scheduleWheelRebuild() }
    }
}

// GradientWheelViewModel.swift
extension GradientWheelViewModel {
    // Build a snapshot of everything the user can tweak
    func snapshot() -> CurrentSettingsV1 {
        CurrentSettingsV1(
            isPowerOn: isPowerOn,
            fanSpeed: fanSpeed,
            included: included,
            opacities: opacities,
            focusedName: focusedName
        )
    }

    // Load a snapshot into the VM and rebuild if needed
    func load(from s: CurrentSettingsV1) {
        isPowerOn   = s.isPowerOn
        fanSpeed    = s.fanSpeed
        included    = s.included
        opacities   = s.opacities
        focusedName = s.focusedName

        // Keep visual state consistent with the snapshot
        if !isPowerOn || included.isEmpty {
            // Off or no mix → show an empty wheel immediately
            selectedColorsWeighted = []
            wheelOpacity = isPowerOn ? 1.0 : 0.0
            // also cancel any pending tasks so nothing repaints over this
            rebuildTask?.cancel()
            clearTask?.cancel()
        } else {
            // On + has mix → compute stops
            wheelOpacity = 1.0
            scheduleWheelRebuild()
        }
    }
}
