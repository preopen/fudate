// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignTokens",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "DesignTokens", targets: ["DesignTokens"]),
    ],
    targets: [
        .target(name: "DesignTokens"),
    ],
    swiftLanguageModes: [.v6]
)
