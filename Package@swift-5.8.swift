// swift-tools-version:5.8
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "Threading",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "Threading", targets: ["Threading"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMinor(from: "3.0.2"))
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
