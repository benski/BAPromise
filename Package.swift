// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BAPromise",
    platforms: [
      .iOS(.v10), .tvOS(.v10), .watchOS(.v3), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "BAPromise",
            targets: ["BAPromise"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-atomics.git",
            from: "0.0.1"
        )
    ],
    targets: [
        .target(
            name: "BAPromise",
            dependencies: [
                .product(name: "Atomics", package: "swift-atomics")
            ]),
        .testTarget(
            name: "BAPromiseTests",
            dependencies: ["BAPromise"]),
    ]
)
