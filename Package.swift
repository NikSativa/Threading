// swift-tools-version:5.6
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NQueue",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(name: "NQueue", targets: ["NQueue"]),
        .library(name: "NQueueTestHelpers", targets: ["NQueueTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        .target(name: "NQueue",
                dependencies: [
                ],
                path: "Source"),
        .target(name: "NQueueTestHelpers",
                dependencies: [
                    "NQueue",
                    "NSpry"
                ],
                path: "TestHelpers"),
        .testTarget(name: "NQueueTests",
                    dependencies: [
                        "NQueue",
                        "NQueueTestHelpers",
                        "NSpry"
                    ],
                    path: "Tests")
    ]
)
