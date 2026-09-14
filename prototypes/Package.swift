// swift-tools-version: 6.2
import PackageDescription
import Foundation

let microphoneInfo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("MicrophoneInfo.plist").path

let package = Package(
    name: "SpeakPrototypes",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "speak-stt", targets: ["SpeakSTT"]),
        .executable(name: "speak-tts", targets: ["SpeakTTS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.15.7", traits: []),
    ],
    targets: [
        .target(name: "PrototypeSupport"),
        .executableTarget(name: "SpeakSTT", dependencies: ["PrototypeSupport", .product(name: "FluidAudio", package: "FluidAudio")], linkerSettings: [.unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", microphoneInfo])]),
        .executableTarget(name: "SpeakTTS", dependencies: ["PrototypeSupport", .product(name: "FluidAudio", package: "FluidAudio")]),
        .testTarget(name: "PrototypeSupportTests", dependencies: ["PrototypeSupport"]),
    ]
)
