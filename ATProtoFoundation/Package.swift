// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ATProtoFoundation",
    platforms: [
        .macOS(.v14),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "ATProtoFoundation",
            targets: ["ATProtoFoundation"]
        )
    ],
    targets: [
        .target(
            name: "ATProtoFoundation",
            dependencies: [],
            path: "Sources/ATProtoFoundation"
        ),
        .testTarget(
            name: "ATProtoFoundationTests",
            dependencies: ["ATProtoFoundation"]
        )
    ]
)
