// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnchorKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "AnchorKit",
            targets: ["AnchorKit"]
        ),
    ],
    dependencies: [
        // No external dependencies - using built-in frameworks
    ],
    targets: [
        .target(
            name: "AnchorKit",
            dependencies: [],
            path: "Sources/AnchorKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AnchorKitTests",
            dependencies: ["AnchorKit"],
            path: "Tests/AnchorKitTests"
        ),
    ]
)
