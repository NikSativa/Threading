// swift-tools-version:5.2

import PackageDescription

// swiftformat:disable all
let package = Package(
    name: "NQueue",
    platforms: [.iOS(.v10), .macOS(.v10_12)],
    products: [
        .library(name: "NQueue", targets: ["NQueue"]),
        .library(name: "NQueueTestHelpers", targets: ["NQueueTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "1.1.3")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.2.0"))
    ],
    targets: [
        .target(name: "NQueue",
                dependencies: [],
                path: "Source"),
        .target(name: "NQueueTestHelpers",
                dependencies: ["NQueue",
                               "NSpry"],
                path: "TestHelpers"),
        .testTarget(name: "NQueueTests",
                    dependencies: ["NQueue",
                                   "NQueueTestHelpers",
                                   "NSpry",
                                   .product(name: "NSpry_Nimble", package: "NSpry"),
                                   "Nimble",
                                   "Quick"],
                    path: "Tests")
    ]
)
