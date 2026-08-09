# VividGradients

> Animated SwiftUI mesh gradient you configure with a `Codable` `GradientConfig` — presets, motion styles, and a copy-as-Swift export. iOS 18+.

Feed `GradientView` a `GradientConfig` and it renders a lattice of coloured
control points whose interior flows according to a chosen motion style — drift,
orbit, swirl, flag, radiance, ripple, spiral, and more.

Requires iOS 18 / macOS 15 / visionOS 2 (uses `MeshGradient`).

## Installation

Add the package in Xcode (File ▸ Add Package Dependencies…) or in `Package.swift`:

```swift
.package(url: "https://github.com/your-org/VividGradients.git", from: "1.0.0")
```

then add `"VividGradients"` to your target's dependencies.

## Usage

```swift
import SwiftUI
import VividGradients

struct ContentView: View {
    var body: some View {
        // A built-in preset…
        GradientView(config: .ember)   // via GradientPreset.ember.config

        // …or a configuration you build yourself.
        GradientView(config: makeConfig())
    }

    func makeConfig() -> GradientConfig {
        var config = GradientPreset.aurora.config
        config.motion = .swirl
        config.velocity = 0.6
        config.rotation = 30            // degrees
        config.noiseOpacity = 0.1
        return config
    }
}
```

`GradientView` owns its own animation clock, so editing `velocity` or toggling
`isAnimating` in a live-updating config stays continuous.

### Public API

- **`GradientView(config: GradientConfig)`** — the view.
- **`GradientConfig`** — a `Codable`, `Hashable` value type holding every knob:
  the colour grid (`colors`, `gridWidth`, `gridHeight`), motion (`motion`,
  `velocity`, `amplitude`, `animateEdges`, …), canvas (`blurRadius`, `rotation`,
  `smoothsColors`) and film-grain noise. Mutating helpers: `setGrid(width:height:)`,
  `randomizePalette(_:)`, `randomizeMotion()`.
- Supporting value types: `GradientPreset`, `MotionStyle`, `BlendModeOption`,
  `PaletteMode`, `RGBAColor`.

## Example app

`Example/` contains a full customization app that drives every `GradientConfig`
knob live — presets, colour grid, motion, noise, rotation, and JSON / Swift
export. Open `Example/VividGradients.xcodeproj`; it depends on this package by
local path.
