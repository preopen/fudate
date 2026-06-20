// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SyncSpike",
    platforms: [
        .iOS("26.0"),
        .macOS(.v15),
    ],
    products: [
        .library(name: "SyncSpike", targets: ["SyncSpike"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "SyncSpike",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "SyncSpikeTests",
            dependencies: ["SyncSpike"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
