import SwiftUI

struct MixingScreen: View {
    // ===== Only the states you actually change in UI flow =====
    @State private var scale: Double = Double(AnimationConfig.targetScale(forActiveScents: 0))
    @State private var activeColors: Int = 0
    @State private var colorPickers: [Color] = Array(repeating: .white, count: 6)
    @State private var intensities:  [Double] = Array(repeating: 1.0,   count: 6)
    @State private var scentNames:   [String] = (1...6).map { "Scent \($0)" }
    
    // Pulses to renderer (−1 = no pulse)
    @State private var addedIndexPulse:   Int32 = -1
    @State private var removedIndexPulse: Int32 = -1

    // Local UI state for sheet-based category picker
    @State private var showingScentsSheet = false
    @State private var selectedCategory: Category? = nil

    // MixingScreen.swift
    private var shaderParams: ShaderParams {
        var p = ShaderParams()                 // takes defaults for knobs
        p.scale = Float(scale)                 // only value this screen actually drives

        // Colors, masks, intensities (targets)
        let sims = colorPickers.map { $0.toSIMD4() }
        p.setColors(sims)
        p.setMasks(activeCount: activeColors)
        p.setIntensities(intensities.map(Float.init))

        // Pulses for add/remove (edge-triggered)
        p.addedIndex   = addedIndexPulse
        p.removedIndex = removedIndexPulse
        return p
    }

    var body: some View {
        let ballSize: CGFloat = 216
        
        VStack(spacing: 0) {
            // ===== Ball (unchanged visuals) =====
            ZStack {
                MetalView(params: shaderParams, paused: showingScentsSheet)
                    .frame(width: ballSize, height: ballSize)
                    .clipShape(Circle())
                    .background(
                        Circle().fill(
                            Color(.sRGB, red: 0.05, green: 0.05, blue: 0.07, opacity: 0.1)
                        )
                    )
                    .compositingGroup()
                
                glassCircle(ballSize)
                    .allowsHitTesting(false)
            }
            .shadow(color: .white.opacity(0.1), radius: 24, x: 0, y: 0)
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
            .padding(.bottom, 24)
            
            // ===== Add Scents panel (same layout; DisclosureGroup -> Button + .sheet) =====
            //let innerShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
            Button {
                showingScentsSheet = true
            } label: {
//                VStack(alignment: .leading, spacing: 0) {
//                    HStack {
//                        Text("Add Scents").font(.headline)
//                        Spacer()
//                        if showingScentsSheet, let cat = selectedCategory {
//                            Text(cat.displayName)
//                                .font(.subheadline)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                    
//                }
//                .contentShape(Rectangle())
                
                Text("Add Scents")
                    .font(.headline)
            }
            .padding(12)
            .buttonStyle(.glass)
            .controlSize(.large)
            .sheet(isPresented: $showingScentsSheet) {
                AddScentsView(
                    selectedCategory: $selectedCategory,
                    selectedNames: Array(scentNames.prefix(activeColors)),   // <- live selection
                    onSelect: { color, name in
                        addScentFromCategory(color: color, name: name)       // <- parent mutates state
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }

            
            
            // ===== Active scents list (unchanged) =====
            ScrollView() {
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
            .padding(12)
            
            
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
            .controlSize(.regular)
        }
        .padding(.horizontal, 24)

    }
    
    // MARK: - Mutations (targets + pulses; visuals unchanged)
    
    private func addScentFromCategory(color: Color, name: String) {
        guard activeColors < 6 else { return }
        let idx = activeColors
        
        colorPickers[idx] = color
        scentNames[idx]   = name
        intensities[idx]  = 0.0   // start off; renderer will fade to 1
        
        activeColors += 1
        
        // UI intent: fade in; scale target derived from policy
        intensities[idx] = 1.0
//        scale = min(scale + 0.5, 1)
        scale = Double(AnimationConfig.targetScale(forActiveScents: activeColors))
        
        // explicit add pulse (edge-triggered)
        addedIndexPulse = Int32(idx)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { addedIndexPulse = -1 }
//        
//        withAnimation(.easeInOut(duration: 0.35)) {
//            showingScentsSheet = false
//            selectedCategory = nil
//        }
    }
    
    private func removeScent(at i: Int) {
        guard activeColors > 0, i < activeColors else { return }

        // Tell renderer which slot to animate down to 0
        removedIndexPulse = Int32(i)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { removedIndexPulse = -1 }

        // Same logic as a slider move: set target to 0 (renderer tweens it)
        intensities[i] = 0.0

        // After the fade, if still zero, compact the arrays
        let fade = 2.0  // keep in sync with Renderer.intensityAnimDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
            // Guard in case user changed their mind
            guard i < activeColors, intensities[i] == 0 else { return }

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

            // Update scale target after compaction
            scale = Double(AnimationConfig.targetScale(forActiveScents: activeColors))
        }
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
