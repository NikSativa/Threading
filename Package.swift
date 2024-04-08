// swift-tools-version:5.9
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "Threading",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .visionOS(.v1),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "Threading", targets: ["Threading"]),
        .library(name: "ThreadingTestHelpers", targets: ["ThreadingTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMajor(from: "2.2.0"))
    ],
    targets: [
        .target(name: "Threading",
                dependencies: [
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .target(name: "ThreadingTestHelpers",
                dependencies: [
                    "Threading",
                    "SpryKit"
                ],
                path: "TestHelpers",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "ThreadingTests",
                    dependencies: [
                        "Threading",
                        "ThreadingTestHelpers",
                        "SpryKit"
                    ],
                    path: "Tests")
    ]
)
