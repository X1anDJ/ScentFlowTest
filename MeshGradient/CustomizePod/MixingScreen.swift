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

        VStack(spacing: 12) {
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
            .shadow(color: .white.opacity(0.15), radius: 24, x: 0, y: 0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)

            VStack {
                HStack {
                    Text("Mix 2 or more scents")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        
                    Spacer()
                }
               
                if activeColors != 0 {
                    VStack {
                        Section {
                            ForEach(0..<activeColors, id: \.self) { i in
                                ListCellScentSlider(
                                    name: scentNames[i],
                                    color: colorPickers[i],
                                    displayed: intensities[i],
                                    onChangeDisplayed: { intensities[i] = $0 },
                                    onRemove: { removeScent(at: i) }
                                )
                                
                            }
                            .padding(.vertical, 6)
                        }
                        
                        .padding(.horizontal, 12)


                    }
                    .padding(.vertical, 8)    // Small space before and after first/last item
                    //.listStyle(.grouped)
                    //.scrollContentBackground(.hidden)
    //                .background(.thinMaterial)
                    .adaptiveGlassBackground(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 0.7)
                            .blendMode(.overlay)
                    )
                }
                
                
                
                // Add Scent row as the last item (only shown when < 6)
                if activeColors < 6 {
                    AddScentListRow {
                        showingScentsSheet = true
                    }
                }
                
                Spacer()

                // ===== Button row (removed bottom Add Scent; only Order remains) =====
                HStack {
                    Button {
                        // start order flow
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bag.fill").font(.headline)
                            Text("Order Scent").fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.glass)    // unchanged per your note
                    .controlSize(.large)
                    .disabled(activeColors < 2)
                    .opacity(activeColors < 2 ? 0.5 : 1.0)
                }
            }
        }
        .padding(.horizontal, 12)
        // ===== Sheet remains the same; triggered from the Add row in the List =====
        .sheet(isPresented: $showingScentsSheet) {
            AddScentsView(
                selectedCategory: $selectedCategory,
                selectedNames: Array(scentNames.prefix(activeColors)),
                onSelect: { color, name in
                    addScentFromCategory(color: color, name: name)
                }
            )
            .modifier(CustomSheetDetents())
//            .presentationDetents([.medium])
//            .presentationDragIndicator(.hidden)
        }
        .environment(\.colorScheme, .dark)
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
        //scale = max(scale - 0.5, 1.0)
        
        // derive scale from policy; renderer eases
        scale = Double(AnimationConfig.targetScale(forActiveScents: activeColors))
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

private struct CustomSheetDetents: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                // 0.6 ~= medium (0.5) * 1.2
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.hidden)
        } else {
            // Fallback: custom detents not available before iOS 16.4
            content
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
    }
}
