// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrepFlowData",
    platforms: [.iOS("26.0"), .macOS(.v15)],
    products: [
        .library(name: "PrepFlowData", targets: ["PrepFlowData"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "PrepFlowData",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "PrepFlowDataTests",
            dependencies: ["PrepFlowData"]
        ),
    ]
)
