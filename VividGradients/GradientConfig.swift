//
//  GradientConfig.swift
//  VividGradients
//
//  Every knob the gradient renderer reads, in one Codable value.
//

import SwiftUI

// MARK: - Color

/// A concrete sRGB color that survives a round trip through JSON.
struct RGBAColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(_ color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        self.init(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            opacity: Double(resolved.opacity)
        )
    }

    init(hue: Double, saturation: Double, brightness: Double, opacity: Double = 1) {
        self.init(Color(hue: hue, saturation: saturation, brightness: brightness, opacity: opacity))
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    func opacity(_ value: Double) -> RGBAColor {
        RGBAColor(red: red, green: green, blue: blue, opacity: value)
    }

    var transparent: RGBAColor { opacity(0) }
}

// MARK: - Blend modes

/// The subset of `BlendMode` that reads well on a gradient, made Codable.
enum BlendModeOption: String, Codable, CaseIterable, Identifiable {
    case normal, overlay, screen, plusLighter, softLight, hardLight
    case multiply, colorDodge, colorBurn, difference, luminosity

    var id: String { rawValue }

    var blendMode: BlendMode {
        switch self {
        case .normal: .normal
        case .overlay: .overlay
        case .screen: .screen
        case .plusLighter: .plusLighter
        case .softLight: .softLight
        case .hardLight: .hardLight
        case .multiply: .multiply
        case .colorDodge: .colorDodge
        case .colorBurn: .colorBurn
        case .difference: .difference
        case .luminosity: .luminosity
        }
    }

    /// `Canvas` draws through `GraphicsContext.BlendMode`, a separate type
    /// from the `BlendMode` the view modifier takes.
    var graphicsBlendMode: GraphicsContext.BlendMode {
        switch self {
        case .normal: .normal
        case .overlay: .overlay
        case .screen: .screen
        case .plusLighter: .plusLighter
        case .softLight: .softLight
        case .hardLight: .hardLight
        case .multiply: .multiply
        case .colorDodge: .colorDodge
        case .colorBurn: .colorBurn
        case .difference: .difference
        case .luminosity: .luminosity
        }
    }

    var label: String {
        switch self {
        case .plusLighter: "Plus Lighter"
        case .softLight: "Soft Light"
        case .hardLight: "Hard Light"
        case .colorDodge: "Color Dodge"
        case .colorBurn: "Color Burn"
        default: rawValue.capitalized
        }
    }
}

// MARK: - Motion

/// Position curves the nodes can follow. Each maps a monotonically increasing
/// `phase` (seconds scaled by velocity) onto a unit-space position.
enum MotionStyle: String, Codable, CaseIterable, Identifiable {
    case still, drift, orbit, bounce, swirl, jitter

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .still: "pause.circle"
        case .drift: "wind"
        case .orbit: "circle.dashed"
        case .bounce: "arrow.up.left.and.arrow.down.right"
        case .swirl: "tornado"
        case .jitter: "waveform.path"
        }
    }

    var blurb: String {
        switch self {
        case .still: "Nodes hold their home position."
        case .drift: "Slow organic wander from two detuned waves."
        case .orbit: "Each node circles its home point."
        case .bounce: "Linear travel that reflects at the turnaround."
        case .swirl: "The whole field rotates around the centre."
        case .jitter: "Fast, small, nervous displacement."
        }
    }

    func position(home: CGPoint, phase p: Double, seed: Double, amplitude a: Double) -> CGPoint {
        let hx = Double(home.x)
        let hy = Double(home.y)
        let s: Double = seed * 2 * .pi

        switch self {
        case .still:
            return home

        case .drift:
            let dx: Double = a * (0.7 * sin(p * 0.53 + s) + 0.3 * sin(p * 0.31 + s * 2.3))
            let dy: Double = a * (0.7 * cos(p * 0.47 + s * 1.7) + 0.3 * cos(p * 0.23 + s * 3.1))
            return CGPoint(x: hx + dx, y: hy + dy)

        case .orbit:
            let dx: Double = a * cos(p * 0.6 + s)
            let dy: Double = a * sin(p * 0.6 + s)
            return CGPoint(x: hx + dx, y: hy + dy)

        case .bounce:
            let dx: Double = a * Self.triangle(p * 0.18 + seed)
            let dy: Double = a * Self.triangle(p * 0.13 + seed * 1.7)
            return CGPoint(x: hx + dx, y: hy + dy)

        case .swirl:
            let rx: Double = hx - 0.5
            let ry: Double = hy - 0.5
            let angle: Double = p * 0.35 + s * 0.15
            let breath: Double = 1 + a * sin(p * 0.5 + s)
            let x: Double = 0.5 + (rx * cos(angle) - ry * sin(angle)) * breath
            let y: Double = 0.5 + (rx * sin(angle) + ry * cos(angle)) * breath
            return CGPoint(x: x, y: y)

        case .jitter:
            let dx: Double = a * 0.25 * (sin(p * 6.3 + s * 3) + sin(p * 9.7 + s * 7))
            let dy: Double = a * 0.25 * (cos(p * 7.1 + s * 5) + cos(p * 11.3 + s * 2))
            return CGPoint(x: hx + dx, y: hy + dy)
        }
    }

    /// Triangle wave in -1...1 with period 1.
    private static func triangle(_ x: Double) -> Double {
        let f = x - floor(x)
        return 4 * abs(f - 0.5) - 1
    }
}

// MARK: - Nodes

struct GradientNode: Codable, Hashable, Identifiable {
    var id = UUID()
    var color: RGBAColor
    /// Gradient reach as a fraction of the canvas' shorter side.
    var radius: Double
    /// Resting position in unit space.
    var home: CGPoint
    /// 0...1 phase offset so nodes don't move in lockstep.
    var seed: Double

    init(color: RGBAColor, radius: Double, home: CGPoint, seed: Double = .random(in: 0...1)) {
        self.color = color
        self.radius = radius
        self.home = home
        self.seed = seed
    }
}

// MARK: - Config

struct GradientConfig: Codable, Hashable {
    // Palette
    var background = RGBAColor(red: 0, green: 0, blue: 0)
    var nodes: [GradientNode] = []
    var shadowNodes: [GradientNode] = []
    var shadowsMove = false

    // Motion
    var motion: MotionStyle = .drift
    var isAnimating = true
    /// Multiplier on elapsed time. 0 freezes, 3 is frantic.
    var velocity: Double = 1
    /// How far a node may stray from home, in unit space.
    var amplitude: Double = 0.25
    /// Radius modulation depth.
    var breathe: Double = 0
    var frameRate: Int = 60

    // Canvas
    var blurRadius: Double = 30
    /// Solid centre of each blob, as a fraction of its radius.
    var coreSize: Double = 0.06
    var nodeBlend: BlendModeOption = .overlay
    var layerBlend: BlendModeOption = .normal

    // Noise
    var noiseOpacity: Double = 0.1
    /// Texture resolution relative to the canvas — lower means chunkier grain.
    var noiseGranularity: Double = 0.7
    var noiseBlend: BlendModeOption = .overlay
    var noiseAnimated = false
    var noiseFrameRate: Double = 12
}

// MARK: - Presets

extension GradientConfig {
    /// The look the app shipped with before the settings panel existed.
    static var ember: GradientConfig {
        var config = GradientConfig()
        config.background = RGBAColor(red: 0, green: 0, blue: 0)
        config.nodes = [
            GradientNode(color: RGBAColor(Color.orange).opacity(0.9), radius: 0.5, home: CGPoint(x: 0.2, y: 0.3), seed: 0.05),
            GradientNode(color: RGBAColor(Color.red).opacity(0.9), radius: 0.45, home: CGPoint(x: 0.6, y: 0.25), seed: 0.31),
            GradientNode(color: RGBAColor(Color.orange).opacity(0.9), radius: 0.6, home: CGPoint(x: 0.4, y: 0.7), seed: 0.58),
            GradientNode(color: RGBAColor(Color.red).opacity(0.85), radius: 0.4, home: CGPoint(x: 0.85, y: 0.6), seed: 0.83)
        ]
        config.shadowNodes = Self.defaultShadows
        config.nodeBlend = .overlay
        config.layerBlend = .normal
        return config
    }

    static var aurora: GradientConfig {
        var config = GradientConfig()
        config.background = RGBAColor(red: 0.02, green: 0.05, blue: 0.09)
        config.nodes = [
            GradientNode(color: RGBAColor(hue: 0.42, saturation: 0.85, brightness: 0.95, opacity: 0.8), radius: 0.55, home: CGPoint(x: 0.25, y: 0.35), seed: 0.1),
            GradientNode(color: RGBAColor(hue: 0.50, saturation: 0.80, brightness: 0.95, opacity: 0.75), radius: 0.5, home: CGPoint(x: 0.7, y: 0.3), seed: 0.4),
            GradientNode(color: RGBAColor(hue: 0.75, saturation: 0.70, brightness: 0.90, opacity: 0.7), radius: 0.6, home: CGPoint(x: 0.45, y: 0.72), seed: 0.65),
            GradientNode(color: RGBAColor(hue: 0.58, saturation: 0.75, brightness: 0.95, opacity: 0.6), radius: 0.45, home: CGPoint(x: 0.85, y: 0.7), seed: 0.9)
        ]
        config.shadowNodes = Self.defaultShadows.map { node in
            var node = node
            node.color = RGBAColor(red: 0, green: 0.02, blue: 0.06, opacity: 0.5)
            return node
        }
        config.nodeBlend = .screen
        config.blurRadius = 45
        config.motion = .drift
        config.velocity = 0.6
        config.amplitude = 0.3
        config.noiseOpacity = 0.08
        return config
    }

    static var neon: GradientConfig {
        var config = GradientConfig()
        config.background = RGBAColor(red: 0.02, green: 0.02, blue: 0.04)
        config.nodes = [
            GradientNode(color: RGBAColor(hue: 0.86, saturation: 0.9, brightness: 1.0, opacity: 0.7), radius: 0.5, home: CGPoint(x: 0.3, y: 0.3), seed: 0.0),
            GradientNode(color: RGBAColor(hue: 0.52, saturation: 0.9, brightness: 1.0, opacity: 0.7), radius: 0.5, home: CGPoint(x: 0.7, y: 0.4), seed: 0.33),
            GradientNode(color: RGBAColor(hue: 0.25, saturation: 0.9, brightness: 1.0, opacity: 0.55), radius: 0.45, home: CGPoint(x: 0.5, y: 0.75), seed: 0.66)
        ]
        config.shadowNodes = []
        config.nodeBlend = .plusLighter
        config.blurRadius = 60
        config.coreSize = 0.02
        config.motion = .orbit
        config.velocity = 0.8
        config.amplitude = 0.18
        config.breathe = 0.2
        config.noiseOpacity = 0.14
        config.noiseGranularity = 0.9
        return config
    }

    static var ocean: GradientConfig {
        var config = GradientConfig()
        config.background = RGBAColor(red: 0.01, green: 0.06, blue: 0.12)
        config.nodes = [
            GradientNode(color: RGBAColor(hue: 0.53, saturation: 0.8, brightness: 0.8, opacity: 0.85), radius: 0.6, home: CGPoint(x: 0.25, y: 0.25), seed: 0.12),
            GradientNode(color: RGBAColor(hue: 0.60, saturation: 0.9, brightness: 0.7, opacity: 0.85), radius: 0.55, home: CGPoint(x: 0.75, y: 0.35), seed: 0.44),
            GradientNode(color: RGBAColor(hue: 0.47, saturation: 0.7, brightness: 0.85, opacity: 0.7), radius: 0.5, home: CGPoint(x: 0.5, y: 0.8), seed: 0.77)
        ]
        config.shadowNodes = Self.defaultShadows
        config.nodeBlend = .screen
        config.blurRadius = 55
        config.motion = .swirl
        config.velocity = 0.4
        config.amplitude = 0.12
        config.breathe = 0.12
        return config
    }

    static var sunset: GradientConfig {
        var config = GradientConfig()
        config.background = RGBAColor(red: 0.09, green: 0.02, blue: 0.10)
        config.nodes = [
            GradientNode(color: RGBAColor(hue: 0.95, saturation: 0.75, brightness: 1.0, opacity: 0.8), radius: 0.55, home: CGPoint(x: 0.3, y: 0.28), seed: 0.2),
            GradientNode(color: RGBAColor(hue: 0.08, saturation: 0.85, brightness: 1.0, opacity: 0.8), radius: 0.5, home: CGPoint(x: 0.7, y: 0.45), seed: 0.5),
            GradientNode(color: RGBAColor(hue: 0.80, saturation: 0.70, brightness: 0.9, opacity: 0.7), radius: 0.6, home: CGPoint(x: 0.45, y: 0.78), seed: 0.8)
        ]
        config.shadowNodes = Self.defaultShadows
        config.nodeBlend = .screen
        config.blurRadius = 40
        config.motion = .bounce
        config.velocity = 0.7
        config.amplitude = 0.22
        return config
    }

    static var mono: GradientConfig {
        var config = GradientConfig()
        config.background = RGBAColor(red: 0.08, green: 0.08, blue: 0.09)
        config.nodes = (0..<4).map { (i: Int) -> GradientNode in
            let radius: Double = 0.4 + Double(i) * 0.05
            let x: Double = 0.25 + Double(i % 2) * 0.5
            let y: Double = 0.3 + Double(i / 2) * 0.4
            let seed: Double = Double(i) / 4
            return GradientNode(
                color: RGBAColor(red: 1, green: 1, blue: 1, opacity: 0.35),
                radius: radius,
                home: CGPoint(x: x, y: y),
                seed: seed
            )
        }
        config.shadowNodes = []
        config.nodeBlend = .softLight
        config.blurRadius = 50
        config.motion = .drift
        config.velocity = 0.5
        config.noiseOpacity = 0.2
        config.noiseGranularity = 1.0
        return config
    }

    static let defaultShadows: [GradientNode] = [
        GradientNode(color: RGBAColor(red: 0, green: 0, blue: 0, opacity: 0.7), radius: 0.3, home: CGPoint(x: 0.3, y: 0.4), seed: 0.17),
        GradientNode(color: RGBAColor(red: 0, green: 0, blue: 0, opacity: 0.7), radius: 0.25, home: CGPoint(x: 0.7, y: 0.3), seed: 0.42),
        GradientNode(color: RGBAColor(red: 0, green: 0, blue: 0, opacity: 0.7), radius: 0.35, home: CGPoint(x: 0.5, y: 0.6), seed: 0.68),
        GradientNode(color: RGBAColor(red: 0, green: 0, blue: 0, opacity: 0.7), radius: 0.28, home: CGPoint(x: 0.8, y: 0.7), seed: 0.93)
    ]
}

enum GradientPreset: String, CaseIterable, Identifiable {
    case ember, aurora, neon, ocean, sunset, mono

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var config: GradientConfig {
        switch self {
        case .ember: .ember
        case .aurora: .aurora
        case .neon: .neon
        case .ocean: .ocean
        case .sunset: .sunset
        case .mono: .mono
        }
    }
}

// MARK: - Randomiser

extension GradientConfig {
    /// Builds a fresh palette around a random base hue, keeping motion settings intact.
    mutating func randomizePalette() {
        let baseHue = Double.random(in: 0...1)
        let scheme = Double.random(in: 0.08...0.35)   // how far hues spread
        let dark = Double.random(in: 0.02...0.12)

        background = RGBAColor(hue: baseHue, saturation: Double.random(in: 0.3...0.8), brightness: dark)

        let count = Int.random(in: 3...5)
        nodes = (0..<count).map { i in
            let hue = (baseHue + scheme * Double(i) + Double.random(in: -0.03...0.03))
                .truncatingRemainder(dividingBy: 1)
            return GradientNode(
                color: RGBAColor(
                    hue: hue < 0 ? hue + 1 : hue,
                    saturation: Double.random(in: 0.6...0.95),
                    brightness: Double.random(in: 0.75...1.0),
                    opacity: Double.random(in: 0.55...0.9)
                ),
                radius: Double.random(in: 0.35...0.65),
                home: CGPoint(x: Double.random(in: 0.15...0.85), y: Double.random(in: 0.15...0.85)),
                seed: Double(i) / Double(count) + Double.random(in: 0...0.1)
            )
        }

        nodeBlend = [.screen, .plusLighter, .overlay, .softLight].randomElement() ?? .screen
    }

    /// Re-rolls motion parameters without touching the palette.
    mutating func randomizeMotion() {
        motion = MotionStyle.allCases.filter { $0 != .still }.randomElement() ?? .drift
        velocity = Double.random(in: 0.3...1.6)
        amplitude = Double.random(in: 0.08...0.35)
        breathe = Bool.random() ? Double.random(in: 0...0.3) : 0
        for index in nodes.indices {
            nodes[index].seed = Double.random(in: 0...1)
        }
    }
}
