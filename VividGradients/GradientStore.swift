//
//  GradientStore.swift
//  VividGradients
//
//  Owns the live config, keeps the animation clock continuous across edits,
//  and persists whatever you were last playing with.
//

import SwiftUI
import Observation

@Observable
final class GradientStore {
    var config: GradientConfig {
        didSet {
            guard config != oldValue else { return }
            if config.velocity != oldValue.velocity || config.isAnimating != oldValue.isAnimating {
                rebaseClock(previous: oldValue)
            }
            schedulePersist()
        }
    }

    /// Set by the settings panel so the preset row can show what's selected.
    var activePreset: GradientPreset?

    @ObservationIgnored private var phaseOffset: Double = 0
    @ObservationIgnored private var epoch: Double = Date.timeIntervalSinceReferenceDate
    @ObservationIgnored private var persistTask: Task<Void, Never>?

    private static let storageKey = "VividGradients.config"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(GradientConfig.self, from: data) {
            config = saved
        } else {
            config = .ember
            activePreset = .ember
        }
    }

    // MARK: Clock

    /// Elapsed animation time, scaled by velocity. Continuous when velocity
    /// changes or the animation is paused and resumed.
    func phase(at date: Date) -> Double {
        guard config.isAnimating else { return phaseOffset }
        return phaseOffset + (date.timeIntervalSinceReferenceDate - epoch) * config.velocity
    }

    private func rebaseClock(previous: GradientConfig) {
        let now = Date.timeIntervalSinceReferenceDate
        if previous.isAnimating {
            phaseOffset += (now - epoch) * previous.velocity
        }
        epoch = now
    }

    // MARK: Editing

    func apply(_ preset: GradientPreset) {
        config = preset.config
        activePreset = preset
    }

    func randomizePalette() {
        config.randomizePalette()
        activePreset = nil
    }

    func randomizeMotion() {
        config.randomizeMotion()
        activePreset = nil
    }

    func addNode() {
        let hue = Double.random(in: 0...1)
        config.nodes.append(
            GradientNode(
                color: RGBAColor(hue: hue, saturation: 0.8, brightness: 0.95, opacity: 0.8),
                radius: 0.5,
                home: CGPoint(x: Double.random(in: 0.2...0.8), y: Double.random(in: 0.2...0.8))
            )
        )
        activePreset = nil
    }

    func addShadowNode() {
        config.shadowNodes.append(
            GradientNode(
                color: RGBAColor(red: 0, green: 0, blue: 0, opacity: 0.7),
                radius: 0.3,
                home: CGPoint(x: Double.random(in: 0.2...0.8), y: Double.random(in: 0.2...0.8))
            )
        )
        activePreset = nil
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
