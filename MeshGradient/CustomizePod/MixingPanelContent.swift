////
////  MixingPanelContent.swift
////  MeshGradient
////
////  Created by Dajun Xian on 9/12/25.
////
//
//
//
//// MARK: - Extracted panel content (design/logic unchanged; now reuses ColorRow)
//private struct MixingPanelContent: View {
//    @Binding var activeColors: Int
//    @Binding var colorPickers: [Color]
//    @Binding var intensities:  [Double]
//    @Binding var scentNames:   [String]
//
//    @Binding var speed: Double
//    @Binding var scale: Double
//    @Binding var warp: Double
//    @Binding var edge: Double
//    @Binding var separation: Double
//    @Binding var contrast: Double
//
//    var onAddedScent: (_ newIndex: Int) -> Void
//    var onRemovedScent: () -> Void
//    var onTapRowCircle: (_ index: Int) -> Void
//
//    @State private var isScentsOpen = false
//    @State private var selectedCategory: Category? = nil
//
//    var body: some View {
//        VStack(spacing: 18) {
//            // ===== Add Scents (native) =====
//            let innerShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
//            DisclosureGroup(isExpanded: $isScentsOpen) {
//                Group {
//                    if let cat = selectedCategory {
//                        categorySubOptionsGrid(for: cat)
//                    } else {
//                        categoriesGrid()
//                    }
//                }
//                .padding(.top, 10)
//            } label: {
//                VStack(alignment: .leading, spacing: 0) {
//                    HStack {
//                        Text("Add Scents")
//                            .font(.headline)
//                        Spacer()
//                        if isScentsOpen, let cat = selectedCategory {
//                            Text(cat.displayName)
//                                .font(.subheadline)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
//                            isScentsOpen.toggle()
//                            if !isScentsOpen { selectedCategory = nil }
//                        }
//                    }
//                }
//            }
//            .padding(12)
//            .background(.thinMaterial, in: innerShape)
//            .overlay(innerShape.strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
//
//            // ===== Current Scents (REUSES ColorRow) =====
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Scents")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//
//                VStack(spacing: 10) {
//                    ForEach(0..<activeColors, id: \.self) { i in
//                        ColorRow(
//                            name: scentNames[i],
//                            color: colorPickers[i],
//                            displayed: intensities[i],
//                            onChangeDisplayed: { intensities[i] = $0 },
//                            onFocusOrToggle: { onTapRowCircle(i) }
//                        )
//                        // Delete button to the right, same logic as before
//                        .overlay(alignment: .trailing) {
//                            Button(role: .destructive) {
//                                removeScent(at: i)
//                                onRemovedScent()
//                            } label: {
//                                Image(systemName: "trash")
//                            }
//                            .padding(.trailing, 8)
//                        }
//                    }
//                }
//            }
//
//            // Motion & Shape
//            GroupBox {
//                VStack(spacing: 8) {
//                    slider("Speed", value: $speed, range: 0...2)
//                    slider("Scale", value: $scale, range: 0.4...4)
//                    slider("Warp",  value: $warp,  range: 0...2)
//                }
//            } label: { label("Motion & Shape", systemImage: "waveform.path.ecg") }
//
//            // Blend
//            GroupBox {
//                VStack(spacing: 8) {
//                    slider("Edge Softness", value: $edge, range: 0...1)
//                    slider("Separation",   value: $separation, range: 0.5...6)
//                    slider("Contrast",     value: $contrast, range: 0.6...1.4)
//                }
//            } label: { label("Blend", systemImage: "wand.and.stars") }
//        }
//    }
