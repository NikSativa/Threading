// swift-tools-version:5.6
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NQueue",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "NQueue", targets: ["NQueue"]),
        .library(name: "NQueueTestHelpers", targets: ["NQueueTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "1.2.9")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "6.1.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "11.2.1"))
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
