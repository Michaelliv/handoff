// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "handoff",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ClipboardCore",
            targets: ["ClipboardCore"]
        ),
        .executable(
            name: "clip",
            targets: ["clip"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "ClipboardCore",
            dependencies: []
        ),
        .executableTarget(
            name: "clip",
            dependencies: [
                "ClipboardCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "ClipboardCoreTests",
            dependencies: ["ClipboardCore"]
        ),
    ]
)
