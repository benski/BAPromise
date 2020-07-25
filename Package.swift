// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BAPromise",
    platforms: [.iOS(.v10), .macOS(.v10_12), .tvOS(.v10), .watchOS(.v6)],
    products: [
        .library(
            name: "BAPromise",
            targets: ["BAPromise"])
    ],
    targets: [
        .target(
            name: "BAPromise",
            path: "Classes",
            publicHeadersPath: ".")
    ]
)