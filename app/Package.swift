// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "Speak",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Speak", targets: ["SpeakApp"]), .executable(name: "speakctl", targets: ["SpeakControl"])],
    dependencies: [
        .package(path: "../prototypes"),
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.15.7", traits: []),
    ],
    targets: [
        .target(name: "SpeakCore"),
        .executableTarget(name: "SpeakControl", dependencies: ["SpeakCore"]),
        .executableTarget(name: "SpeakApp", dependencies: ["SpeakCore", .product(name: "PrototypeSupport", package: "prototypes"), .product(name: "FluidAudio", package: "FluidAudio")]),
        .testTarget(name: "SpeakCoreTests", dependencies: ["SpeakCore"]),
    ]
)
