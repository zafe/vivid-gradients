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
                        Button("Randomize Palette", systemImage: "paintbrush") { store.randomizePalette() }
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
            ForEach($store.config.nodes) { $node in
                NodeEditor(node: $node, supportsOpacity: true)
            }
            .onDelete { store.config.nodes.remove(atOffsets: $0) }

            Button("Add Node", systemImage: "plus.circle") { store.addNode() }
        } header: {
            Text("Color nodes (\(store.config.nodes.count))")
        } footer: {
            Text("Each node is a radial gradient blended into the field. Swipe to delete.")
        }

        Section {
            Toggle("Shadows follow motion", isOn: $store.config.shadowsMove)

            ForEach($store.config.shadowNodes) { $node in
                NodeEditor(node: $node, supportsOpacity: true)
            }
            .onDelete { store.config.shadowNodes.remove(atOffsets: $0) }

            Button("Add Shadow", systemImage: "plus.circle") { store.addShadowNode() }
        } header: {
            Text("Shadow nodes (\(store.config.shadowNodes.count))")
        } footer: {
            Text("Dark blobs that carve depth out of the color field.")
        }
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
                          range: 0...0.6, format: "%.2f")
            LabeledSlider(title: "Breathe", value: $store.config.breathe,
                          range: 0...0.6, format: "%.2f")

            Picker("Frame rate", selection: $store.config.frameRate) {
                Text("30 fps").tag(30)
                Text("60 fps").tag(60)
                Text("120 fps").tag(120)
            }
            .pickerStyle(.segmented)
        }

        Section {
            Button("Re-roll node phases", systemImage: "shuffle") {
                for index in store.config.nodes.indices {
                    store.config.nodes[index].seed = Double.random(in: 0...1)
                }
            }
        } footer: {
            Text("Phase decides where each node sits in its cycle — re-roll to break up nodes moving in step.")
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
        Section("Softness") {
            LabeledSlider(title: "Blur", value: $store.config.blurRadius,
                          range: 0...150, format: "%.0f")
            LabeledSlider(title: "Core", value: $store.config.coreSize,
                          range: 0...0.6, format: "%.2f")
        }

        Section {
            Picker("Between nodes", selection: $store.config.nodeBlend) {
                ForEach(BlendModeOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("Onto background", selection: $store.config.layerBlend) {
                ForEach(BlendModeOption.allCases) { Text($0.label).tag($0) }
            }
        } header: {
            Text("Blending")
        } footer: {
            Text("Nodes blend with each other first, then the whole layer composites onto the background. Overlay gives the moody original; screen and plus lighter give vivid.")
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
            ZStack {
                config.background.color
                HStack(spacing: -8) {
                    ForEach(config.nodes.prefix(4)) { node in
                        Circle()
                            .fill(node.color.color)
                            .frame(width: 18, height: 18)
                            .blur(radius: 4)
                    }
                }
            }
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

private struct NodeEditor: View {
    @Binding var node: GradientNode
    let supportsOpacity: Bool

    var body: some View {
        DisclosureGroup {
            LabeledSlider(title: "Size", value: $node.radius, range: 0.05...1.2, format: "%.2f")
            LabeledSlider(title: "X", value: $node.home.x.asDouble, range: -0.2...1.2, format: "%.2f")
            LabeledSlider(title: "Y", value: $node.home.y.asDouble, range: -0.2...1.2, format: "%.2f")
            LabeledSlider(title: "Phase", value: $node.seed, range: 0...1, format: "%.2f")
        } label: {
            HStack(spacing: 12) {
                ColorPicker("", selection: $node.color.asColor, supportsOpacity: supportsOpacity)
                    .labelsHidden()
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(format: "size %.2f", node.radius))
                    Text(String(format: "at %.2f, %.2f", node.home.x, node.home.y))
                        .foregroundStyle(.secondary)
                }
                .font(.caption.monospacedDigit())
            }
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

extension Binding where Value == CGFloat {
    /// `CGPoint` stores CGFloat; the sliders all speak Double.
    var asDouble: Binding<Double> {
        Binding<Double>(
            get: { Double(wrappedValue) },
            set: { wrappedValue = CGFloat($0) }
        )
    }
}

#Preview {
    SettingsPanelView(store: GradientStore())
}
