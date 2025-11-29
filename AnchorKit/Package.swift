// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnchorKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "AnchorKit",
            targets: ["AnchorKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/tijs/ATProtoFoundation.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "AnchorKit",
            dependencies: ["ATProtoFoundation"],
            path: "Sources/AnchorKit"
        ),
        .testTarget(
            name: "AnchorKitTests",
            dependencies: ["AnchorKit"],
            path: "Tests/AnchorKitTests"
        )
    ]
)
