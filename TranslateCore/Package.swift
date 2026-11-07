// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TranslateCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TranslateCore", targets: ["TranslateCore"]),
    ],
    targets: [
        .target(name: "TranslateCore", dependencies: ["llama"]),
        .binaryTarget(name: "llama", path: "Frameworks/llama.xcframework"),
        .testTarget(name: "TranslateCoreTests", dependencies: ["TranslateCore"]),
    ]
)
