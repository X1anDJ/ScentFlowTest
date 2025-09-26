import SwiftUI

struct MixingScreen: View {
    // ===== Shader knobs (defaults) =====
    @State private var speed: Double      = 1.8
    @State private var scale: Double      = 0.5   // start at 1.0; Renderer animates toward this
    @State private var warp: Double       = 2.0
    @State private var edge: Double       = 0.7
    @State private var separation: Double = 0.5
    @State private var contrast: Double   = 0.8

    // Scents arrays (max 6) — start empty
    @State private var activeColors: Int = 0
    @State private var colorPickers: [Color] = Array(repeating: .black, count: 6)
    @State private var intensities:  [Double] = Array(repeating: 1.0,   count: 6)
    @State private var scentNames:   [String] = (1...6).map { "Scent \($0)" }

    // For color picking via the row's circle button
    @State private var colorPickerIndex: Int? = nil

    @State private var addedIndexPulse: Int32 = -1
    
    // ===== Shader params =====
    private var shaderParams: ShaderParams {
        var p = ShaderParams()
        p.speed = Float(speed)
        p.scale = Float(scale)       // Renderer will smooth this to GPU over 3s
        p.warp  = Float(warp)
        p.edge  = Float(edge)
        p.separation = Float(separation)
        p.contrast   = Float(contrast)

        let sims = colorPickers.map { $0.toSIMD4() }
        p.color1 = sims[0]; p.color2 = sims[1]; p.color3 = sims[2]
        p.color4 = sims[3]; p.color5 = sims[4]; p.color6 = sims[5]

        // masks from count (no mock/solo white)
        p.mask1 = activeColors >= 1 ? 1 : 0
        p.mask2 = activeColors >= 2 ? 1 : 0
        p.mask3 = activeColors >= 3 ? 1 : 0
        p.mask4 = activeColors >= 4 ? 1 : 0
        p.mask5 = activeColors >= 5 ? 1 : 0
        p.mask6 = activeColors >= 6 ? 1 : 0

        // intensities
        p.intensity1 = Float(intensities[0])
        p.intensity2 = Float(intensities[1])
        p.intensity3 = Float(intensities[2])
        p.intensity4 = Float(intensities[3])
        p.intensity5 = Float(intensities[4])
        p.intensity6 = Float(intensities[5])
        return p
    }

    var body: some View {
        let ballSize: CGFloat = 216

        VStack(spacing: 0) {
            // ===== 1) Ball — MetalView clipped to circle + glass discs =====
            ZStack {
                MetalView(params: shaderParams)
                    .frame(width: ballSize, height: ballSize)
                    .clipShape(Circle())
                    .background(                       // shows through only when fragment is transparent
                        Circle().fill(
                            Color(.sRGB, red: 0.05, green: 0.05, blue: 0.07, opacity: 0.1)
                        )
                    )
                    .compositingGroup()


                // Clear glass disc (iOS 26+) or material fallback
                glassCircle(ballSize)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)

            // ===== 2) Mixing panel content wrapped to mimic Control card =====
            CardContainer(title: "Mixing") {
                MixingPanelContent(
                    activeColors: $activeColors,
                    colorPickers: $colorPickers,
                    intensities: $intensities,
                    scentNames: $scentNames,
                    speed: $speed,
                    scale: $scale,
                    warp: $warp,
                    edge: $edge,
                    separation: $separation,
                    contrast: $contrast,
                    onAddedScent: { newIndex in
                        intensities[newIndex] = 1.0
                        // Target scale: step +0.7 (Renderer animates to it over 3s)
                        let maxScale = 3.5
                        scale = min(scale + 0.5, maxScale)
                    },
                    onRemovedScent: {
                        // Target scale: step -0.7 (down to 1.0)
                        let minScale = 1.0
                        scale = max(scale - 0.5, minScale)
                    },
                    onTapRowCircle: { i in
                        colorPickerIndex = i
                    }
                )
            }
            .padding(.horizontal, 4)

            // ===== 3) Order Scent (native glass button) =====
            GlassOrderButton(title: "Order Scent", systemImage: "bag.fill") {
                // TODO: start order flow
            }
        }
        // Single sheet for color picking, triggered by the row’s circle button.
        .sheet(isPresented: Binding(
            get: { colorPickerIndex != nil },
            set: { if !$0 { colorPickerIndex = nil } }
        )) {
            let i = colorPickerIndex ?? 0
            NavigationStack {
                Form {
                    Section(header: Text(scentNames[i])) {
                        ColorPicker("Color", selection: Binding(
                            get: { colorPickers[i] },
                            set: { colorPickers[i] = $0 }
                        ))
                    }
                }
                .navigationTitle("Pick Color")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { colorPickerIndex = nil }
                    }
                }
            }
        }
    }
}

// MARK: - Extracted panel content (design/logic unchanged; now reuses ColorRow)
private struct MixingPanelContent: View {
    @Binding var activeColors: Int
    @Binding var colorPickers: [Color]
    @Binding var intensities:  [Double]
    @Binding var scentNames:   [String]

    @Binding var speed: Double
    @Binding var scale: Double
    @Binding var warp: Double
    @Binding var edge: Double
    @Binding var separation: Double
    @Binding var contrast: Double

    var onAddedScent: (_ newIndex: Int) -> Void
    var onRemovedScent: () -> Void
    var onTapRowCircle: (_ index: Int) -> Void

    @State private var isScentsOpen = false
    @State private var selectedCategory: Category? = nil

    var body: some View {
        VStack(spacing: 18) {
            // ===== Add Scents (native) =====
            let innerShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
            DisclosureGroup(isExpanded: $isScentsOpen) {
                Group {
                    if let cat = selectedCategory {
                        categorySubOptionsGrid(for: cat)
                    } else {
                        categoriesGrid()
                    }
                }
                .padding(.top, 10)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Add Scents")
                            .font(.headline)
                        Spacer()
                        if isScentsOpen, let cat = selectedCategory {
                            Text(cat.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isScentsOpen.toggle()
                            if !isScentsOpen { selectedCategory = nil }
                        }
                    }
                }
            }
            .padding(12)
            .background(.thinMaterial, in: innerShape)
            //.overlay(innerShape.strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))

            // ===== Current Scents (REUSES ColorRow) =====
            VStack(alignment: .leading, spacing: 10) {
                Text("Scents")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    ForEach(0..<activeColors, id: \.self) { i in
                        ScentControllerSlider(
                            name: scentNames[i],
                            color: colorPickers[i],
                            displayed: intensities[i],
                            onChangeDisplayed: { intensities[i] = $0 },
                            onFocusOrToggle: { onTapRowCircle(i) },
                            onRemove: {
                                removeScent(at: i)
                                onRemovedScent()
                            }
                        )
                    }
                }
            }

            // Motion & Shape
            GroupBox {
                VStack(spacing: 8) {
                    slider("Speed", value: $speed, range: 0...2)
                    slider("Scale", value: $scale, range: 0.4...4)
                    slider("Warp",  value: $warp,  range: 0...2)
                }
            } label: { label("Motion & Shape", systemImage: "waveform.path.ecg") }

            // Blend
            GroupBox {
                VStack(spacing: 8) {
                    slider("Edge Softness", value: $edge, range: 0...1)
                    slider("Separation",   value: $separation, range: 0.5...6)
                    slider("Contrast",     value: $contrast, range: 0.6...1.4)
                }
            } label: { label("Blend", systemImage: "wand.and.stars") }
        }
    }

    // MARK: - Categories
    private enum Category: CaseIterable {
        case red, orange, brown, yellow, green, cyan, violet
        var color: Color {
            switch self {
            case .red:    return .red
            case .orange: return .orange
            case .brown:  return .brown
            case .yellow: return .yellow
            case .green:  return .green
            case .cyan:   return .cyan
            case .violet: return .purple
            }
        }
        var label: String {
            switch self {
            case .red: return "Warm"
            case .orange: return "Fruit"
            case .brown: return "Woody"
            case .yellow: return "Flower"
            case .green:  return "Grass"
            case .cyan:   return "Ozonic"
            case .violet: return "Mystery"
            }
        }
        var displayName: String { label }
        var optionsEN: [String] {
            switch self {
            case .red:    return ["Pepper","Cinnamon","Clove"]
            case .orange: return ["Orange","Lemon","Grapefruit"]
            case .brown:  return ["Sandalwood","Cedar","Pine"]
            case .yellow: return ["Jasmine","Rose","Osmanthus"]
            case .green:  return ["Mint","Green Leaves","Fresh Grass"]
            case .cyan:   return ["Sea Breeze","Water Vapor","Petrichor"]
            case .violet: return ["Vanilla","Resin","Frankincense"]
            }
        }
    }

    private func categoriesGrid() -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(Category.allCases, id: \.self) { cat in
                VStack(spacing: 8) {
                    solidSwatch(tint: cat.color)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                selectedCategory = cat
                                isScentsOpen = true
                            }
                        }
                    Text(cat.label)
                        .font(.caption)
                }
            }
        }
    }

    private func categorySubOptionsGrid(for cat: Category) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(cat.optionsEN, id: \.self) { name in
                VStack(spacing: 8) {
                    solidSwatch(tint: cat.color)
                        .onTapGesture {
                            addScentFromCategory(color: cat.color, name: name)
                        }
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    // Add scent → close disclosure; parent handles ball scaling (renderer eases scale)
    private func addScentFromCategory(color: Color, name: String) {
        guard activeColors < 6 else { return }
        let idx = activeColors
        colorPickers[idx] = color
        scentNames[idx]  = name

        // Start from 0 so the fade is visible
        intensities[idx] = 0.0
        activeColors += 1

        // Single, synced transaction: fade-in + collapse
        withAnimation(.easeInOut(duration: 0.35)) {
            onAddedScent(idx)
            isScentsOpen = false
            selectedCategory = nil
        }
    }

    // Remove scent
    private func removeScent(at i: Int) {
        guard activeColors > 0, i < activeColors else { return }
        if i < activeColors - 1 {
            for j in i..<(activeColors - 1) {
                colorPickers[j] = colorPickers[j + 1]
                intensities[j]  = intensities[j + 1]
                scentNames[j]   = scentNames[j + 1]
            }
        }
        activeColors -= 1
        colorPickers[activeColors] = .black
        intensities[activeColors]  = 1.0
        scentNames[activeColors]   = "Scent \(activeColors + 1)"
    }

    private func solidSwatch(tint: Color) -> some View {
        ZStack {
            Circle().fill(tint.opacity(0.7))

            //Circle().stroke(tint.opacity(0.8), lineWidth: 1.4)
        }
        .frame(width: 44, height: 44)
        
    }

    // Reusable bits
    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }
    
    private func label(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 8) { Image(systemName: systemImage); Text(text) }
    }
}

// MARK: - Glass Order Button (native Button with iOS 26 glass effect)
private struct GlassOrderButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
       // let shape = Capsule(style: .continuous)
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage).font(.headline)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
    }
}

// MARK: - Glass helper for the ZStack ball
@ViewBuilder
private func glassCircle(_ size: CGFloat) -> some View {
    if #available(iOS 26.0, *) {
        Color.clear
            .frame(width: size, height: size)
            .glassEffect(.clear, in: .circle)
    } else {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: size, height: size)
    }
}
