import SwiftUI

struct MixingScreen: View {
    // ===== Only the states you actually change in UI flow =====
    @State private var scale: Double = 0.2               // target scale; renderer eases
    @State private var activeColors: Int = 0
    @State private var colorPickers: [Color] = Array(repeating: .white, count: 6)
    @State private var intensities:  [Double] = Array(repeating: 1.0,   count: 6)
    @State private var scentNames:   [String] = (1...6).map { "Scent \($0)" }
    
    // Pulses to renderer (−1 = no pulse)
    @State private var addedIndexPulse:   Int32 = -1
    @State private var removedIndexPulse: Int32 = -1
    
    // Local UI state for category disclosure
    @State private var isScentsOpen = false
    @State private var selectedCategory: Category? = nil
    

    // ===== Build ShaderParams each frame (targets + pulses) =====
    private var shaderParams: ShaderParams {
        // ===== Fixed “knob” constants since you’re not editing them in UI =====
        let kSpeed: Float      = 1.4
        let kWarp: Float       = 2.0
        let kEdge: Float       = 0.7
        let kSeparation: Float = 0.5
        let kContrast: Float   = 0.8
        
        var p = ShaderParams()
        p.speed      = kSpeed
        p.scale      = Float(scale)     // target; renderer eases
        p.warp       = kWarp
        p.edge       = kEdge
        p.separation = kSeparation
        p.contrast   = kContrast
        
        // colors
        let sims = colorPickers.map { $0.toSIMD4() }
        p.color1 = sims[0]; p.color2 = sims[1]; p.color3 = sims[2]
        p.color4 = sims[3]; p.color5 = sims[4]; p.color6 = sims[5]
        
        // masks derived from activeColors
        p.mask1 = activeColors >= 1 ? 1 : 0
        p.mask2 = activeColors >= 2 ? 1 : 0
        p.mask3 = activeColors >= 3 ? 1 : 0
        p.mask4 = activeColors >= 4 ? 1 : 0
        p.mask5 = activeColors >= 5 ? 1 : 0
        p.mask6 = activeColors >= 6 ? 1 : 0
        
        // intensities (targets)
        p.intensity1 = Float(intensities[0])
        p.intensity2 = Float(intensities[1])
        p.intensity3 = Float(intensities[2])
        p.intensity4 = Float(intensities[3])
        p.intensity5 = Float(intensities[4])
        p.intensity6 = Float(intensities[5])
        
        // explicit pulses
        p.addedIndex   = addedIndexPulse
        p.removedIndex = removedIndexPulse
        return p
    }
    
    var body: some View {
        let ballSize: CGFloat = 216
        
        VStack(spacing: 0) {
            // ===== Ball (unchanged visuals) =====
            ZStack {
                MetalView(params: shaderParams)
                    .frame(width: ballSize, height: ballSize)
                    .clipShape(Circle())
                    .background(
                        Circle().fill(
                            Color(.sRGB, red: 0.05, green: 0.05, blue: 0.07, opacity: 0.1)
                        )
                    )
                    .compositingGroup()
                
                glassCircle(ballSize)     // ← keep your 2026 glass API
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            
            // ===== Add Scents panel (unchanged UI flow, no tuning GroupBoxes) =====
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
                        Text("Add Scents").font(.headline)
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
            
            // ===== Active scents list (unchanged) =====
            VStack(spacing: 10) {
                ForEach(0..<activeColors, id: \.self) { i in
                    ScentControllerSlider(
                        name: scentNames[i],
                        color: colorPickers[i],
                        displayed: intensities[i],
                        onChangeDisplayed: { intensities[i] = $0 },   // UI writes target; renderer eases
                        onRemove: { removeScent(at: i) }
                    )
                }
            }
            
            // ===== CTA (unchanged; keep the glass button style) =====
            Button {
                // start order flow
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill").font(.headline)
                    Text("Order Scent").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass)    // ← unchanged per your note
            .controlSize(.extraLarge)
        }
        .padding(.horizontal, 12)

    }
    
    
    // MARK: - Categories UI (unchanged visuals)
    
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
    
    private func solidSwatch(tint: Color) -> some View {
        ZStack { Circle().fill(tint.opacity(0.7)) }
            .frame(width: 44, height: 44)
    }
    
    // MARK: - Mutations (targets + pulses; visuals unchanged)
    
    private func addScentFromCategory(color: Color, name: String) {
        guard activeColors < 6 else { return }
        let idx = activeColors
        
        colorPickers[idx] = color
        scentNames[idx]   = name
        intensities[idx]  = 0.0   // start off; renderer will fade to 1
        
        activeColors += 1
        
        // UI intent: fade in and nudge scale target
        intensities[idx] = 1.0
        scale = min(scale + 0.2, 1)
        
        // explicit add pulse (edge-triggered)
        addedIndexPulse = Int32(idx)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { addedIndexPulse = -1 }
        
        withAnimation(.easeInOut(duration: 0.35)) {
            isScentsOpen = false
            selectedCategory = nil
        }
    }
    
    private func removeScent(at i: Int) {
        guard activeColors > 0, i < activeColors else { return }
        
        // pulse BEFORE compaction so renderer can ghost the correct slot
        removedIndexPulse = Int32(i)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { removedIndexPulse = -1 }
        
        if i < activeColors - 1 {
            for j in i..<(activeColors - 1) {
                colorPickers[j] = colorPickers[j + 1]
                intensities[j]  = intensities[j + 1]
                scentNames[j]   = scentNames[j + 1]
            }
        }
        activeColors -= 1
        colorPickers[activeColors] = .white
        intensities[activeColors]  = 1.0
        scentNames[activeColors]   = "Scent \(activeColors + 1)"
        
        // nudge scale down (target); renderer eases
        scale = max(scale - 0.5, 1.0)
    }
}

// MARK: - Glass helper for the ZStack ball (UNCHANGED)
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
