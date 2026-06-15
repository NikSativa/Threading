// swift-tools-version:6.0
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "Threading",
    platforms: [
        .iOS(.v15),
        .macOS(.v14),
        .macCatalyst(.v15),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "Threading", targets: ["Threading"]),
        .library(name: "ThreadingStatic", type: .static, targets: ["Threading"]),
        .library(name: "ThreadingDynamic", type: .dynamic, targets: ["Threading"])
    ],
    targets: [
        .target(name: "Threading",
                path: "Source",
                resources: [
                    .process("PrivacyInfo.xcprivacy")
                ],
                swiftSettings: [
                    .define("supportsVisionOS", .when(platforms: [.visionOS]))
                ]),
        .testTarget(name: "ThreadingTests",
                    dependencies: [
                        "Threading",
                    ],
                    path: "Tests",
                    swiftSettings: [
                        .define("supportsVisionOS", .when(platforms: [.visionOS]))
                    ])
    ]
)
