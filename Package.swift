// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VividGradients",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "VividGradients", targets: ["VividGradients"])
    ],
    targets: [
        .target(
            name: "VividGradients",
            // The renderer uses a shared, non-Sendable noise-texture cache;
            // Swift 5 language mode keeps that valid without concurrency churn.
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
