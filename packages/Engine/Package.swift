// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Engine",
    platforms: [
        .iOS("26.0"),
        .macOS(.v15),
    ],
    products: [
        .library(name: "Engine", targets: ["Engine"]),
    ],
    targets: [
        .target(name: "Engine"),
        .testTarget(
            name: "EngineTests",
            dependencies: ["Engine"],
            resources: [.copy("golden")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
