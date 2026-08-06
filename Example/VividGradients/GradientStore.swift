//
//  GradientStore.swift
//  VividGradients example
//
//  Owns the live config for the customization UI and persists whatever you
//  were last playing with. The animation clock lives in the package's
//  `GradientView`, so this is purely an editing model.
//

import SwiftUI
import Observation
import VividGradients

@Observable
final class GradientStore {
    var config: GradientConfig {
        didSet {
            guard config != oldValue else { return }
            schedulePersist()
        }
    }

    /// Set by the settings panel so the preset row can show what's selected.
    var activePreset: GradientPreset?

    @ObservationIgnored private var persistTask: Task<Void, Never>?

    private static let storageKey = "VividGradients.config"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(GradientConfig.self, from: data) {
            config = saved
        } else {
            config = GradientPreset.ember.config
            activePreset = .ember
        }
    }

    // MARK: Editing

    func apply(_ preset: GradientPreset) {
        config = preset.config
        activePreset = preset
    }

    func randomizePalette(_ mode: PaletteMode = .dark) {
        config.randomizePalette(mode)
        activePreset = nil
    }

    func randomizeMotion() {
        config.randomizeMotion()
        activePreset = nil
    }

    func setGrid(width: Int, height: Int) {
        config.setGrid(width: width, height: height)
        activePreset = nil
    }

    func rerollPhases() {
        config.motionSeed = Double.random(in: 0...1)
    }

    var configJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: Persistence

    /// Sliders fire on every frame of a drag, so coalesce writes.
    private func schedulePersist() {
        persistTask?.cancel()
        let snapshot = config
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            if let data = try? JSONEncoder().encode(snapshot) {
                UserDefaults.standard.set(data, forKey: Self.storageKey)
            }
        }
    }
}
