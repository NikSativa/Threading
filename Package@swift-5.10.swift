// swift-tools-version:5.10
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "Threading",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .macCatalyst(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "Threading", targets: ["Threading"]),
        .library(name: "ThreadingStatic", type: .static, targets: ["Threading"]),
        .library(name: "ThreadingDynamic", type: .dynamic, targets: ["Threading"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/SpryKit.git", from: "3.0.2")
    ],
    targets: [
        .target(name: "Threading",
                path: "Source",
                resources: [
                    .process("PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "ThreadingTests",
                    dependencies: [
                        "Threading",
                        "SpryKit"
                    ],
                    path: "Tests")
    ]
)
