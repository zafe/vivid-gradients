//
//  SettingsPanelView.swift
//  VividGradients
//
//  The tabbed control panel. Presented as a sheet over the live canvas so
//  every change is visible while you drag.
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case palette, motion, noise, canvas

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .palette: "paintpalette"
        case .motion: "waveform.path.ecg"
        case .noise: "circle.grid.3x3.fill"
        case .canvas: "square.on.square.dashed"
        }
    }
}

struct SettingsPanelView: View {
    @Bindable var store: GradientStore
    @State private var tab: SettingsTab = .palette

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                presetRow

                Picker("Tab", selection: $tab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Label(tab.label, systemImage: tab.symbol).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                Form {
                    switch tab {
                    case .palette: paletteTab
                    case .motion: motionTab
                    case .noise: noiseTab
                    case .canvas: canvasTab
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Gradient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.config.isAnimating.toggle()
                    } label: {
                        Image(systemName: store.config.isAnimating ? "pause.fill" : "play.fill")
                    }
                    .accessibilityLabel(store.config.isAnimating ? "Pause" : "Play")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Menu("Randomize Palette", systemImage: "paintbrush") {
                            ForEach(PaletteMode.allCases) { mode in
                                Button("\(mode.label) Palette", systemImage: mode.symbol) {
                                    store.randomizePalette(mode)
                                }
                            }
                        }
                        Button("Randomize Motion", systemImage: "dice") { store.randomizeMotion() }
                        Divider()
                        Button("Reset to Ember", systemImage: "arrow.counterclockwise") { store.apply(.ember) }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: Presets

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GradientPreset.allCases) { preset in
                    Button {
                        store.apply(preset)
                    } label: {
                        PresetSwatch(preset: preset, isSelected: store.activePreset == preset)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    // MARK: Palette

    @ViewBuilder
    private var paletteTab: some View {
        Section("Background") {
            ColorPicker("Base color", selection: $store.config.background.asColor, supportsOpacity: false)
        }

        Section {
            Stepper("Columns: \(store.config.gridWidth)", value: columnsBinding, in: 2...6)
            Stepper("Rows: \(store.config.gridHeight)", value: rowsBinding, in: 2...6)
        } header: {
            Text("Mesh grid")
        } footer: {
            Text("Corner points stay pinned; the \(interiorCount) interior point\(interiorCount == 1 ? "" : "s") flow with the motion style.")
        }

        Section {
            LazyVGrid(columns: colorGridColumns, spacing: 10) {
                ForEach(0..<store.config.pointCount, id: \.self) { index in
                    ColorPicker("", selection: colorBinding(index), supportsOpacity: false)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)

            Menu {
                ForEach(PaletteMode.allCases) { mode in
                    Button("\(mode.label) Palette", systemImage: mode.symbol) {
                        store.randomizePalette(mode)
                    }
                }
            } label: {
                Label("Shuffle colors", systemImage: "die.face.5")
            }
        } header: {
            Text("Control point colors")
        } footer: {
            Text("Each well is one vertex of the mesh, laid out top-left to bottom-right.")
        }
    }

    private var colorGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: store.config.gridWidth)
    }

    private var interiorCount: Int {
        max(0, (store.config.gridWidth - 2)) * max(0, (store.config.gridHeight - 2))
    }

    private var columnsBinding: Binding<Int> {
        Binding(
            get: { store.config.gridWidth },
            set: { store.setGrid(width: $0, height: store.config.gridHeight) }
        )
    }

    private var rowsBinding: Binding<Int> {
        Binding(
            get: { store.config.gridHeight },
            set: { store.setGrid(width: store.config.gridWidth, height: $0) }
        )
    }

    private func colorBinding(_ index: Int) -> Binding<Color> {
        Binding(
            get: {
                guard store.config.colors.indices.contains(index) else { return .black }
                return store.config.colors[index].color
            },
            set: { newValue in
                guard store.config.colors.indices.contains(index) else { return }
                store.config.colors[index] = RGBAColor(newValue)
            }
        )
    }

    // MARK: Motion

    @ViewBuilder
    private var motionTab: some View {
        Section {
            Picker("Style", selection: $store.config.motion) {
                ForEach(MotionStyle.allCases) { style in
                    Label(style.label, systemImage: style.symbol).tag(style)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Style")
        } footer: {
            Text(store.config.motion.blurb)
        }

        Section("Timing") {
            Toggle("Animating", isOn: $store.config.isAnimating)

            LabeledSlider(title: "Velocity", value: $store.config.velocity,
                          range: 0...3, format: "%.2f×")
            LabeledSlider(title: "Amplitude", value: $store.config.amplitude,
                          range: 0...0.5, format: "%.2f")

            Picker("Frame rate", selection: $store.config.frameRate) {
                Text("30 fps").tag(30)
                Text("60 fps").tag(60)
                Text("120 fps").tag(120)
            }
            .pickerStyle(.segmented)
        }

        Section {
            Toggle("Animate edge points", isOn: $store.config.animateEdges)
            Button("Re-roll phases", systemImage: "shuffle") { store.rerollPhases() }
        } footer: {
            Text("By default only interior points move, keeping the edges anchored. Enable edge animation to let the border ripple too. Re-roll to reshuffle which points lead.")
        }
    }

    // MARK: Noise

    @ViewBuilder
    private var noiseTab: some View {
        Section {
            LabeledSlider(title: "Opacity", value: $store.config.noiseOpacity,
                          range: 0...0.5, format: "%.3f")
            LabeledSlider(title: "Granularity", value: $store.config.noiseGranularity,
                          range: 0.02...1.0, format: "%.2f")
            Picker("Blend", selection: $store.config.noiseBlend) {
                ForEach(BlendModeOption.allCases) { Text($0.label).tag($0) }
            }
        } header: {
            Text("Grain")
        } footer: {
            Text("Granularity is texture resolution relative to the screen — lower is chunkier.")
        }

        Section {
            Toggle("Animate grain", isOn: $store.config.noiseAnimated)
            if store.config.noiseAnimated {
                LabeledSlider(title: "Grain rate", value: $store.config.noiseFrameRate,
                              range: 1...30, format: "%.0f fps")
            }
        } footer: {
            Text("Cycles through \(NoiseTextureStore.frameCount) cached noise frames for a film-grain shimmer.")
        }
    }

    // MARK: Canvas

    @ViewBuilder
    private var canvasTab: some View {
        Section {
            Toggle("Smooth colors", isOn: $store.config.smoothsColors)
        } footer: {
            Text("Higher-quality colour interpolation across the mesh. Off gives a flatter, more banded blend.")
        }

        Section("Softness") {
            LabeledSlider(title: "Blur", value: $store.config.blurRadius,
                          range: 0...60, format: "%.0f")
        }

        Section {
            Button("Copy config as JSON", systemImage: "doc.on.doc") {
                copyConfig()
            }
        } footer: {
            Text("Paste into another project to reproduce this exact look.")
        }
    }

    private func copyConfig() {
        #if canImport(UIKit)
        UIPasteboard.general.string = store.configJSON
        #endif
    }
}

// MARK: - Components

private struct PresetSwatch: View {
    let preset: GradientPreset
    let isSelected: Bool

    var body: some View {
        let config = preset.config

        VStack(spacing: 6) {
            MeshGradient(
                width: config.gridWidth,
                height: config.gridHeight,
                points: config.homePoints,
                colors: config.meshColors,
                background: config.background.color,
                smoothsColors: config.smoothsColors
            )
            .frame(width: 64, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.15),
                                  lineWidth: isSelected ? 2 : 1)
            )

            Text(preset.label)
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
    }
}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}

// MARK: - Binding helpers

extension Binding where Value == RGBAColor {
    /// Bridges the Codable color to `ColorPicker`.
    var asColor: Binding<Color> {
        Binding<Color>(
            get: { wrappedValue.color },
            set: { wrappedValue = RGBAColor($0) }
        )
    }
}

#Preview {
    SettingsPanelView(store: GradientStore())
}
