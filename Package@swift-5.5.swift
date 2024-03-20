// swift-tools-version:5.5
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NQueue",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "NQueue", targets: ["NQueue"]),
        .library(name: "NQueueTestHelpers", targets: ["NQueueTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "2.1.4"))
    ],
    targets: [
        .target(name: "NQueue",
                dependencies: [
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .target(name: "NQueueTestHelpers",
                dependencies: [
                    "NQueue",
                    "NSpry"
                ],
                path: "TestHelpers",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "NQueueTests",
                    dependencies: [
                        "NQueue",
                        "NQueueTestHelpers",
                        "NSpry"
                    ],
                    path: "Tests")
    ]
)
