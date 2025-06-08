// swift-tools-version:5.9
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "Threading",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
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
