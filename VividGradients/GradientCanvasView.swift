//
//  GradientCanvasView.swift
//  VividGradients
//
//  Draws the whole field in a single Canvas so node positions can be a
//  function of time rather than a pair of keyframes.
//

import SwiftUI

struct GradientCanvasView: View {
    let store: GradientStore

    var body: some View {
        let config = store.config

        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / Double(config.frameRate),
                                    paused: !config.isAnimating)) { timeline in
                Canvas { context, size in
                    draw(config, into: &context, size: size, phase: store.phase(at: timeline.date))
                }
            }

            NoiseLayer(
                opacity: config.noiseOpacity,
                granularity: config.noiseGranularity,
                blendMode: config.noiseBlend.blendMode,
                animated: config.noiseAnimated,
                frameRate: config.noiseFrameRate
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private func draw(_ config: GradientConfig, into context: inout GraphicsContext, size: CGSize, phase: Double) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(config.background.color))

        if config.blurRadius > 0 {
            context.addFilter(.blur(radius: CGFloat(config.blurRadius)))
        }
        context.blendMode = config.layerBlend.graphicsBlendMode

        // One isolated layer so the nodes blend against each other, then
        // composite onto the background as a unit.
        context.drawLayer { layer in
            layer.blendMode = config.nodeBlend.graphicsBlendMode

            let shadowMotion = config.shadowsMove ? config.motion : .still
            for node in config.shadowNodes {
                drawNode(node, motion: shadowMotion, config: config, into: &layer, size: size, phase: phase)
            }
            for node in config.nodes {
                drawNode(node, motion: config.motion, config: config, into: &layer, size: size, phase: phase)
            }
        }
    }

    private func drawNode(
        _ node: GradientNode,
        motion: MotionStyle,
        config: GradientConfig,
        into context: inout GraphicsContext,
        size: CGSize,
        phase: Double
    ) {
        let unit = motion.position(home: node.home, phase: phase, seed: node.seed, amplitude: config.amplitude)
        let center = CGPoint(x: unit.x * size.width, y: unit.y * size.height)

        let breathAngle: Double = phase * 1.3 + node.seed * (2 * Double.pi)
        let breathScale: Double = 1 + config.breathe * sin(breathAngle)
        let shortSide: Double = Double(min(size.width, size.height))
        let scaled: Double = shortSide * node.radius * breathScale
        let radius = CGFloat(max(1, scaled))

        let box = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: box),
            with: .radialGradient(
                Gradient(colors: [node.color.color, node.color.transparent.color]),
                center: center,
                startRadius: radius * CGFloat(config.coreSize),
                endRadius: radius
            )
        )
    }
}

// MARK: - Noise

struct NoiseLayer: View {
    var opacity: Double
    var granularity: Double
    var blendMode: BlendMode
    var animated: Bool
    var frameRate: Double

    var body: some View {
        if opacity > 0 {
            GeometryReader { geometry in
                let dimensions = NoiseTextureStore.dimensions(for: geometry.size, granularity: granularity)

                if animated {
                    TimelineView(.periodic(from: .now, by: 1.0 / max(1, frameRate))) { timeline in
                        let step = Int(timeline.date.timeIntervalSinceReferenceDate * max(1, frameRate))
                        noise(dimensions, frame: step % NoiseTextureStore.frameCount)
                    }
                } else {
                    noise(dimensions, frame: 0)
                }
            }
            .ignoresSafeArea()
        }
    }

    private func noise(_ dimensions: (width: Int, height: Int), frame: Int) -> some View {
        Image(decorative: NoiseTextureStore.shared.image(width: dimensions.width,
                                                         height: dimensions.height,
                                                         frame: frame),
              scale: 1.0)
            .resizable()
            .opacity(opacity)
            .blendMode(blendMode)
    }
}

/// Generating a full-screen noise bitmap costs a few milliseconds, which is
/// fine once and ruinous every frame. Cache a handful of frames per size and
/// cycle through them when animated noise is on.
final class NoiseTextureStore {
    static let shared = NoiseTextureStore()
    static let frameCount = 6

    private var cache: [String: CGImage] = [:]

    static func dimensions(for size: CGSize, granularity: Double) -> (width: Int, height: Int) {
        (width: max(8, Int(size.width * granularity)),
         height: max(8, Int(size.height * granularity)))
    }

    func image(width: Int, height: Int, frame: Int) -> CGImage {
        let key = "\(width)x\(height)#\(frame)"
        if let cached = cache[key] { return cached }

        let image = Self.makeNoise(width: width, height: height)
        // Bound memory when the granularity slider is dragged across its range.
        if cache.count > 48 { cache.removeAll(keepingCapacity: true) }
        cache[key] = image
        return image
    }

    private static func makeNoise(width: Int, height: Int) -> CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height)
        for i in pixels.indices {
            pixels[i] = UInt8.random(in: 0...255)
        }

        let context = pixels.withUnsafeMutableBytes { buffer in
            CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            )
        }

        guard let image = context?.makeImage() else {
            // A 1x1 mid-grey is invisible under .overlay, so a failure here
            // degrades to "no grain" rather than crashing.
            let fallback = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 1,
                                     space: CGColorSpaceCreateDeviceGray(),
                                     bitmapInfo: CGImageAlphaInfo.none.rawValue)
            fallback?.setFillColor(gray: 0.5, alpha: 1)
            fallback?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            return fallback!.makeImage()!
        }
        return image
    }
}

#Preview {
    GradientCanvasView(store: GradientStore())
}
