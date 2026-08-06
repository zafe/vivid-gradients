//
//  GradientView.swift
//  VividGradients
//
//  The package's public entry point: hand it a `GradientConfig` and it renders
//  the animated mesh gradient. It owns its own animation clock, so it needs no
//  external store.
//

import SwiftUI

public struct GradientView: View {
    private let config: GradientConfig

    public init(config: GradientConfig) {
        self.config = config
    }

    // A velocity-scaled clock kept continuous across velocity / play-pause
    // changes, so editing those live never jumps the animation.
    @State private var epoch: Double = Date.timeIntervalSinceReferenceDate
    @State private var phaseOffset: Double = 0

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Behind the mesh so any optional blur (or a rotation rounding
                // gap) fades into the base tone rather than into transparency.
                config.background.color

                TimelineView(.animation(minimumInterval: 1.0 / Double(config.frameRate),
                                        paused: !config.isAnimating)) { timeline in
                    let phase = phase(at: timeline.date)
                    MeshGradient(
                        width: config.gridWidth,
                        height: config.gridHeight,
                        points: config.meshPoints(at: phase),
                        colors: config.meshColors,
                        background: config.background.color,
                        smoothsColors: config.smoothsColors
                    )
                    .rotationEffect(.degrees(config.rotation))
                    .scaleEffect(coverScale(size: geo.size, degrees: config.rotation))
                    .blur(radius: CGFloat(config.blurRadius))
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
        }
        .ignoresSafeArea()
        // Fold elapsed time into the offset before the rate changes, so speed
        // and play/pause edits are seamless rather than jarring.
        .onChange(of: config.velocity) { oldVelocity, _ in
            let now = Date.timeIntervalSinceReferenceDate
            if config.isAnimating { phaseOffset += (now - epoch) * oldVelocity }
            epoch = now
        }
        .onChange(of: config.isAnimating) { wasAnimating, _ in
            let now = Date.timeIntervalSinceReferenceDate
            if wasAnimating { phaseOffset += (now - epoch) * config.velocity }
            epoch = now
        }
    }

    private func phase(at date: Date) -> Double {
        guard config.isAnimating else { return phaseOffset }
        return phaseOffset + (date.timeIntervalSinceReferenceDate - epoch) * config.velocity
    }

    /// Uniform scale that keeps a rotated rectangle covering the screen, so a
    /// turned gradient never reveals the background at the corners.
    private func coverScale(size: CGSize, degrees: Double) -> CGFloat {
        let radians: Double = degrees * .pi / 180
        let c: Double = abs(cos(radians))
        let s: Double = abs(sin(radians))
        let w: Double = max(Double(size.width), 1)
        let h: Double = max(Double(size.height), 1)
        let coverW: Double = (w * c + h * s) / w
        let coverH: Double = (h * c + w * s) / h
        return CGFloat(max(coverW, coverH))
    }
}

#Preview {
    GradientView(config: .ember)
}
