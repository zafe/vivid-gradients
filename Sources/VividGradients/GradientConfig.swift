//
//  GradientConfig.swift
//  VividGradients
//
//  Every knob the gradient renderer reads, in one Codable value.
//

import SwiftUI

// MARK: - Color

/// A concrete sRGB color that survives a round trip through JSON.
public struct RGBAColor: Codable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    public init(_ color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        self.init(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            opacity: Double(resolved.opacity)
        )
    }

    public init(hue: Double, saturation: Double, brightness: Double, opacity: Double = 1) {
        self.init(Color(hue: hue, saturation: saturation, brightness: brightness, opacity: opacity))
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    func opacity(_ value: Double) -> RGBAColor {
        RGBAColor(red: red, green: green, blue: blue, opacity: value)
    }

    var transparent: RGBAColor { opacity(0) }
}

// MARK: - Blend modes

/// The subset of `BlendMode` that reads well on a gradient, made Codable.
public enum BlendModeOption: String, Codable, CaseIterable, Identifiable {
    case normal, overlay, screen, plusLighter, softLight, hardLight
    case multiply, colorDodge, colorBurn, difference, luminosity

    public var id: String { rawValue }

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

    public var label: String {
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
public enum MotionStyle: String, Codable, CaseIterable, Identifiable {
    case still, drift, orbit, bounce, swirl, jitter
    case flag, radiance, ripple, pendulum, figureEight, spiral

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .figureEight: "Figure 8"
        default: rawValue.capitalized
        }
    }

    public var symbol: String {
        switch self {
        case .still: "pause.circle"
        case .drift: "wind"
        case .orbit: "circle.dashed"
        case .bounce: "arrow.up.left.and.arrow.down.right"
        case .swirl: "tornado"
        case .jitter: "waveform.path"
        case .flag: "flag.fill"
        case .radiance: "sun.max.fill"
        case .ripple: "dot.radiowaves.left.and.right"
        case .pendulum: "metronome.fill"
        case .figureEight: "infinity"
        case .spiral: "hurricane"
        }
    }

    public var blurb: String {
        switch self {
        case .still: "Nodes hold their home position."
        case .drift: "Slow organic wander from two detuned waves."
        case .orbit: "Each node circles its home point."
        case .bounce: "Linear travel that reflects at the turnaround."
        case .swirl: "The whole field rotates around the centre."
        case .jitter: "Fast, small, nervous displacement."
        case .flag: "A wave travels left to right, rippling like cloth in wind."
        case .radiance: "Nodes pulse outward from the centre and back, together."
        case .ripple: "Concentric rings — nodes bob by their distance from centre."
        case .pendulum: "An eased side-to-side swing with a gentle vertical bob."
        case .figureEight: "Each node traces a looping figure-eight around home."
        case .spiral: "Rotation whose radius grows and shrinks — a winding spiral."
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

        case .flag:
            // A wave whose phase depends on x, so it sweeps across the field
            // like the ripple running down a flag. Amplitude eases in from the
            // left edge (the "pole") so that side stays calmer.
            let travel: Double = sin(hx * 6.0 - p * 2.0 + s)
            let anchor: Double = 0.35 + 0.65 * hx
            let dy: Double = a * travel * anchor
            let dx: Double = a * 0.15 * cos(hx * 6.0 - p * 2.0 + s)
            return CGPoint(x: hx + dx, y: hy + dy)

        case .radiance:
            // Every node slides along its own ray from the centre, in unison,
            // so the whole field breathes like a burst of light.
            let rx: Double = hx - 0.5
            let ry: Double = hy - 0.5
            let len: Double = max(1e-4, (rx * rx + ry * ry).squareRoot())
            let pulse: Double = sin(p * 0.9 + s * 0.2)
            let scale: Double = a * pulse / len
            return CGPoint(x: hx + rx * scale, y: hy + ry * scale)

        case .ripple:
            // Same radial slide as radiance, but the phase is offset by
            // distance from centre, so peaks travel outward as rings.
            let rx: Double = hx - 0.5
            let ry: Double = hy - 0.5
            let len: Double = max(1e-4, (rx * rx + ry * ry).squareRoot())
            let wave: Double = sin(len * 9.0 - p * 2.0 + s * 0.3)
            let scale: Double = a * wave / len
            return CGPoint(x: hx + rx * scale, y: hy + ry * scale)

        case .pendulum:
            // Eased horizontal swing, with a vertical bob at twice the rate so
            // the node dips at each end of its arc.
            let swing: Double = sin(p * 0.9 + s)
            let dx: Double = a * swing
            let dy: Double = a * 0.25 * (1 - cos(p * 1.8 + s * 2))
            return CGPoint(x: hx + dx, y: hy + dy)

        case .figureEight:
            // A 2:1 Lissajous figure — the classic lying-down figure eight.
            let t: Double = p * 0.7
            let dx: Double = a * sin(t + s)
            let dy: Double = a * 0.6 * sin(2 * t + s)
            return CGPoint(x: hx + dx, y: hy + dy)

        case .spiral:
            // Orbit at a radius that itself swells and contracts, winding the
            // node in and back out.
            let angle: Double = p * 0.8 + s
            let radius: Double = a * (0.35 + 0.65 * (0.5 + 0.5 * sin(p * 0.33 + s)))
            let dx: Double = radius * cos(angle)
            let dy: Double = radius * sin(angle)
            return CGPoint(x: hx + dx, y: hy + dy)
        }
    }

    /// Triangle wave in -1...1 with period 1.
    private static func triangle(_ x: Double) -> Double {
        let f = x - floor(x)
        return 4 * abs(f - 0.5) - 1
    }
}

// MARK: - Config

/// The gradient is a `MeshGradient`: a `gridWidth × gridHeight` lattice of
/// control points, each with a colour. Corner points stay pinned; interior
/// points (and optionally edge points) are displaced over time by the chosen
/// `MotionStyle`, which is what makes the mesh flow.
public struct GradientConfig: Codable, Hashable {
    // Palette
    public var background = RGBAColor(red: 0, green: 0, blue: 0)
    /// Row-major colours, one per control point (count == gridWidth * gridHeight).
    public var colors: [RGBAColor] = []
    public var gridWidth: Int = 4
    public var gridHeight: Int = 4
    /// SwiftUI's higher-quality colour interpolation across the mesh.
    public var smoothsColors = true

    // Motion
    public var motion: MotionStyle = .drift
    public var isAnimating = true
    /// Multiplier on elapsed time. 0 freezes, 3 is frantic.
    public var velocity: Double = 1
    /// How far a control point may stray from home, in unit space.
    public var amplitude: Double = 0.16
    /// When on, non-corner edge points slide along their edge too.
    public var animateEdges = false
    /// Global phase shift, so "re-roll" can reshuffle who leads.
    public var motionSeed: Double = 0
    public var frameRate: Int = 60

    // Canvas
    /// Optional extra softening on top of the mesh's own smoothness.
    public var blurRadius: Double = 0
    /// Whole-gradient rotation in degrees. The renderer over-scales the mesh so
    /// a turn never exposes the corners.
    public var rotation: Double = 0

    // Noise
    public var noiseOpacity: Double = 0.08
    /// Texture resolution relative to the canvas — lower means chunkier grain.
    public var noiseGranularity: Double = 0.7
    public var noiseBlend: BlendModeOption = .overlay
    public var noiseAnimated = false
    public var noiseFrameRate: Double = 12

    /// A default configuration (the ember preset's colours arrive via presets).
    public init() {}

    public var pointCount: Int { gridWidth * gridHeight }

    func colorIndex(col: Int, row: Int) -> Int { row * gridWidth + col }

    /// Colours mapped for `MeshGradient`, padded/trimmed to the current grid so
    /// a size change can never crash the renderer mid-edit.
    var meshColors: [Color] {
        let need = pointCount
        var result = colors.map(\.color)
        if result.count < need {
            let filler = colors.last?.color ?? .black
            result += Array(repeating: filler, count: need - result.count)
        } else if result.count > need {
            result = Array(result.prefix(need))
        }
        return result
    }

    /// The lattice at rest — used for previews and as the motion's home grid.
    var homePoints: [SIMD2<Float>] {
        var points: [SIMD2<Float>] = []
        points.reserveCapacity(pointCount)
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                points.append(SIMD2<Float>(Float(homeX(col)), Float(homeY(row))))
            }
        }
        return points
    }

    /// The lattice displaced to a given animation phase.
    func meshPoints(at phase: Double) -> [SIMD2<Float>] {
        let w = gridWidth
        let h = gridHeight
        var points: [SIMD2<Float>] = []
        points.reserveCapacity(w * h)

        for row in 0..<h {
            for col in 0..<w {
                let hx: Double = homeX(col)
                let hy: Double = homeY(row)
                let onSideEdge: Bool = (col == 0 || col == w - 1)
                let onTopEdge: Bool = (row == 0 || row == h - 1)
                let isCorner: Bool = onSideEdge && onTopEdge
                let isInterior: Bool = !onSideEdge && !onTopEdge
                let canMove: Bool = isInterior || (animateEdges && !isCorner)

                var px: Double = hx
                var py: Double = hy

                if canMove && motion != .still {
                    let seed: Double = vertexSeed(col: col, row: row)
                    let moved = motion.position(home: CGPoint(x: hx, y: hy),
                                                phase: phase, seed: seed, amplitude: amplitude)
                    if isInterior {
                        px = Self.clamp(Double(moved.x), 0.04, 0.96)
                        py = Self.clamp(Double(moved.y), 0.04, 0.96)
                    } else if onTopEdge {
                        // Top/bottom rows may slide horizontally, never vertically.
                        px = Self.clamp(Double(moved.x), 0.06, 0.94)
                    } else {
                        // Left/right columns may slide vertically.
                        py = Self.clamp(Double(moved.y), 0.06, 0.94)
                    }
                }

                points.append(SIMD2<Float>(Float(px), Float(py)))
            }
        }
        return points
    }

    private func homeX(_ col: Int) -> Double {
        gridWidth > 1 ? Double(col) / Double(gridWidth - 1) : 0.5
    }

    private func homeY(_ row: Int) -> Double {
        gridHeight > 1 ? Double(row) / Double(gridHeight - 1) : 0.5
    }

    /// A stable per-vertex phase in 0..<1, shifted by `motionSeed`.
    private func vertexSeed(col: Int, row: Int) -> Double {
        let raw: Double = sin(Double(col) * 12.9898 + Double(row) * 78.233) * 43758.5453
        let frac: Double = raw - floor(raw)
        let shifted: Double = frac + motionSeed
        return shifted - floor(shifted)
    }

    static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }

    /// Resizes the lattice, resampling existing colours by nearest neighbour so
    /// the look is roughly preserved across a grid change.
    public mutating func setGrid(width: Int, height: Int) {
        let newW = Self.clampInt(width, 2, 6)
        let newH = Self.clampInt(height, 2, 6)
        let oldW = gridWidth
        let oldH = gridHeight
        let old = colors

        var next: [RGBAColor] = []
        next.reserveCapacity(newW * newH)
        for row in 0..<newH {
            for col in 0..<newW {
                let u: Double = newW > 1 ? Double(col) / Double(newW - 1) : 0
                let v: Double = newH > 1 ? Double(row) / Double(newH - 1) : 0
                let oc: Int = oldW > 1 ? Int((u * Double(oldW - 1)).rounded()) : 0
                let orow: Int = oldH > 1 ? Int((v * Double(oldH - 1)).rounded()) : 0
                let idx: Int = orow * oldW + oc
                if old.indices.contains(idx) {
                    next.append(old[idx])
                } else {
                    next.append(RGBAColor(hue: u, saturation: 0.7, brightness: 0.9))
                }
            }
        }

        gridWidth = newW
        gridHeight = newH
        colors = next
    }

    private static func clampInt(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}

// MARK: - Colour ramps

extension RGBAColor {
    func lerp(to other: RGBAColor, t: Double) -> RGBAColor {
        RGBAColor(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t,
            opacity: opacity + (other.opacity - opacity) * t
        )
    }

    /// Samples an evenly-spaced colour ramp at `t` in 0...1.
    static func sample(_ ramp: [RGBAColor], at t: Double) -> RGBAColor {
        guard let first = ramp.first else { return RGBAColor(red: 0, green: 0, blue: 0) }
        guard ramp.count > 1 else { return first }
        let clamped: Double = GradientConfig.clamp(t, 0, 1)
        let scaled: Double = clamped * Double(ramp.count - 1)
        let index: Int = Int(floor(scaled))
        if index >= ramp.count - 1 { return ramp[ramp.count - 1] }
        return ramp[index].lerp(to: ramp[index + 1], t: scaled - Double(index))
    }
}

// MARK: - Presets

extension GradientConfig {
    /// Lays a colour ramp diagonally across a fresh grid.
    static func makeColors(width: Int, height: Int, ramp: [RGBAColor]) -> [RGBAColor] {
        let span: Double = Double((width - 1) + (height - 1))
        var out: [RGBAColor] = []
        out.reserveCapacity(width * height)
        for row in 0..<height {
            for col in 0..<width {
                let t: Double = span > 0 ? Double(col + row) / span : 0
                out.append(RGBAColor.sample(ramp, at: t))
            }
        }
        return out
    }

    private static func base(
        ramp: [RGBAColor],
        background: RGBAColor,
        motion: MotionStyle,
        velocity: Double,
        amplitude: Double,
        width: Int = 4,
        height: Int = 4
    ) -> GradientConfig {
        var config = GradientConfig()
        config.gridWidth = width
        config.gridHeight = height
        config.colors = makeColors(width: width, height: height, ramp: ramp)
        config.background = background
        config.motion = motion
        config.velocity = velocity
        config.amplitude = amplitude
        return config
    }

    /// A warm ember/flame ramp — the app's original spirit, now as a mesh.
    static var ember: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.02, saturation: 0.90, brightness: 0.45),
                RGBAColor(hue: 0.03, saturation: 0.95, brightness: 0.90),
                RGBAColor(hue: 0.07, saturation: 0.95, brightness: 1.00),
                RGBAColor(hue: 0.12, saturation: 0.80, brightness: 1.00)
            ],
            background: RGBAColor(red: 0.04, green: 0.0, blue: 0.0),
            motion: .drift, velocity: 1.0, amplitude: 0.16
        )
    }

    static var aurora: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.45, saturation: 0.80, brightness: 0.70),
                RGBAColor(hue: 0.50, saturation: 0.85, brightness: 0.95),
                RGBAColor(hue: 0.60, saturation: 0.80, brightness: 0.90),
                RGBAColor(hue: 0.75, saturation: 0.70, brightness: 0.85)
            ],
            background: RGBAColor(red: 0.02, green: 0.05, blue: 0.09),
            motion: .drift, velocity: 0.6, amplitude: 0.22
        )
    }

    static var neon: GradientConfig {
        var config = base(
            ramp: [
                RGBAColor(hue: 0.86, saturation: 0.90, brightness: 1.0),
                RGBAColor(hue: 0.52, saturation: 0.90, brightness: 1.0),
                RGBAColor(hue: 0.30, saturation: 0.90, brightness: 1.0),
                RGBAColor(hue: 0.70, saturation: 0.90, brightness: 1.0)
            ],
            background: RGBAColor(red: 0.02, green: 0.02, blue: 0.04),
            motion: .orbit, velocity: 0.8, amplitude: 0.16
        )
        config.noiseOpacity = 0.12
        config.noiseGranularity = 0.9
        return config
    }

    static var ocean: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.62, saturation: 0.90, brightness: 0.50),
                RGBAColor(hue: 0.55, saturation: 0.90, brightness: 0.80),
                RGBAColor(hue: 0.50, saturation: 0.85, brightness: 0.90),
                RGBAColor(hue: 0.47, saturation: 0.70, brightness: 0.95)
            ],
            background: RGBAColor(red: 0.01, green: 0.06, blue: 0.12),
            motion: .swirl, velocity: 0.4, amplitude: 0.14
        )
    }

    static var sunset: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.80, saturation: 0.70, brightness: 0.70),
                RGBAColor(hue: 0.92, saturation: 0.80, brightness: 1.0),
                RGBAColor(hue: 0.05, saturation: 0.85, brightness: 1.0),
                RGBAColor(hue: 0.11, saturation: 0.80, brightness: 1.0)
            ],
            background: RGBAColor(red: 0.06, green: 0.01, blue: 0.08),
            motion: .bounce, velocity: 0.7, amplitude: 0.20
        )
    }

    static var mono: GradientConfig {
        var config = base(
            ramp: [
                RGBAColor(red: 0.18, green: 0.18, blue: 0.20),
                RGBAColor(red: 0.45, green: 0.45, blue: 0.48),
                RGBAColor(red: 0.70, green: 0.70, blue: 0.74),
                RGBAColor(red: 0.92, green: 0.92, blue: 0.95)
            ],
            background: RGBAColor(red: 0.05, green: 0.05, blue: 0.06),
            motion: .drift, velocity: 0.5, amplitude: 0.18
        )
        config.noiseOpacity = 0.16
        config.noiseGranularity = 1.0
        return config
    }

    // MARK: Light presets — pale grounds with soft, pastel ramps.

    /// Cherry-blossom pinks and peach on warm white.
    static var blossom: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.95, saturation: 0.45, brightness: 0.99),
                RGBAColor(hue: 0.02, saturation: 0.40, brightness: 0.98),
                RGBAColor(hue: 0.08, saturation: 0.45, brightness: 0.99),
                RGBAColor(hue: 0.83, saturation: 0.38, brightness: 0.96)
            ],
            background: RGBAColor(hue: 0.95, saturation: 0.05, brightness: 0.99),
            motion: .drift, velocity: 0.5, amplitude: 0.18
        )
    }

    /// Cool lavender-to-mint haze on a blue-white ground.
    static var mist: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.72, saturation: 0.35, brightness: 0.96),
                RGBAColor(hue: 0.62, saturation: 0.42, brightness: 0.96),
                RGBAColor(hue: 0.54, saturation: 0.40, brightness: 0.97),
                RGBAColor(hue: 0.45, saturation: 0.38, brightness: 0.97)
            ],
            background: RGBAColor(hue: 0.60, saturation: 0.04, brightness: 0.99),
            motion: .swirl, velocity: 0.35, amplitude: 0.14
        )
    }

    /// Lemon, peach and pink pastels — a scoop of sorbet.
    static var sorbet: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.13, saturation: 0.50, brightness: 1.00),
                RGBAColor(hue: 0.08, saturation: 0.50, brightness: 0.99),
                RGBAColor(hue: 0.98, saturation: 0.48, brightness: 0.98),
                RGBAColor(hue: 0.03, saturation: 0.55, brightness: 0.97)
            ],
            background: RGBAColor(hue: 0.10, saturation: 0.05, brightness: 1.00),
            motion: .drift, velocity: 0.7, amplitude: 0.20
        )
    }

    /// Soft greens rising to a warm sky.
    static var meadow: GradientConfig {
        base(
            ramp: [
                RGBAColor(hue: 0.30, saturation: 0.42, brightness: 0.92),
                RGBAColor(hue: 0.22, saturation: 0.48, brightness: 0.95),
                RGBAColor(hue: 0.15, saturation: 0.48, brightness: 0.98),
                RGBAColor(hue: 0.50, saturation: 0.38, brightness: 0.97)
            ],
            background: RGBAColor(hue: 0.30, saturation: 0.05, brightness: 0.98),
            motion: .flag, velocity: 0.6, amplitude: 0.16
        )
    }

    /// A near-neutral warm off-white — subtle beige and taupe.
    static var linen: GradientConfig {
        var config = base(
            ramp: [
                RGBAColor(hue: 0.09, saturation: 0.18, brightness: 0.94),
                RGBAColor(hue: 0.07, saturation: 0.22, brightness: 0.90),
                RGBAColor(hue: 0.10, saturation: 0.12, brightness: 0.96),
                RGBAColor(hue: 0.08, saturation: 0.08, brightness: 0.98)
            ],
            background: RGBAColor(hue: 0.09, saturation: 0.06, brightness: 0.98),
            motion: .drift, velocity: 0.4, amplitude: 0.12
        )
        config.noiseOpacity = 0.12
        config.noiseGranularity = 1.0
        return config
    }
}

public enum GradientPreset: String, CaseIterable, Identifiable {
    case ember, aurora, neon, ocean, sunset, mono
    case blossom, mist, sorbet, meadow, linen

    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }

    public var config: GradientConfig {
        switch self {
        case .ember: .ember
        case .aurora: .aurora
        case .neon: .neon
        case .ocean: .ocean
        case .sunset: .sunset
        case .mono: .mono
        case .blossom: .blossom
        case .mist: .mist
        case .sorbet: .sorbet
        case .meadow: .meadow
        case .linen: .linen
        }
    }
}

// MARK: - Randomiser

/// Which end of the light spectrum a random palette should land in.
public enum PaletteMode: String, CaseIterable, Identifiable {
    case dark, light

    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
    public var symbol: String { self == .dark ? "moon.stars.fill" : "sun.max.fill" }
}

extension GradientConfig {
    /// Rebuilds the colour grid around a random base hue, keeping motion intact.
    /// `mode` decides whether the background reads dark with vivid colours, or
    /// light with softer ones.
    public mutating func randomizePalette(_ mode: PaletteMode = .dark) {
        let baseHue: Double = Double.random(in: 0...1)
        let spread: Double = Double.random(in: 0.12...0.5)

        switch mode {
        case .dark:
            background = RGBAColor(hue: baseHue,
                                   saturation: Double.random(in: 0.3...0.7),
                                   brightness: Double.random(in: 0.02...0.12))
        case .light:
            background = RGBAColor(hue: baseHue,
                                   saturation: Double.random(in: 0.04...0.14),
                                   brightness: Double.random(in: 0.90...0.99))
        }

        let ramp: [RGBAColor] = (0..<4).map { (i: Int) -> RGBAColor in
            var hue: Double = baseHue + spread * Double(i) + Double.random(in: -0.03...0.03)
            hue -= floor(hue)
            let saturation: Double
            let brightness: Double
            switch mode {
            case .dark:
                // Vivid, bright colours that glow against the dark ground.
                saturation = Double.random(in: 0.65...0.95)
                brightness = Double.random(in: 0.55...1.0)
            case .light:
                // Softer, slightly deeper tones so they still read on near-white.
                saturation = Double.random(in: 0.40...0.75)
                brightness = Double.random(in: 0.80...0.97)
            }
            return RGBAColor(hue: hue, saturation: saturation, brightness: brightness)
        }
        colors = Self.makeColors(width: gridWidth, height: gridHeight, ramp: ramp)
    }

    /// Re-rolls motion parameters without touching the palette.
    public mutating func randomizeMotion() {
        motion = MotionStyle.allCases.filter { $0 != .still }.randomElement() ?? .drift
        velocity = Double.random(in: 0.3...1.6)
        amplitude = Double.random(in: 0.08...0.28)
        motionSeed = Double.random(in: 0...1)
    }
}
