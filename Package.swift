// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RudderIntegrationSprig",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "RudderIntegrationSprig",
            targets: ["RudderIntegrationSprig"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/UserLeap/userleap-ios-sdk-releases", .upToNextMajor(from: "4.29.0")),
        .package(url: "https://github.com/rudderlabs/rudder-sdk-swift.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "RudderIntegrationSprig",
            dependencies: [
                .product(name: "UserLeapKit", package: "userleap-ios-sdk-releases"),
                .product(name: "RudderStackAnalytics", package: "rudder-sdk-swift")
            ]
        ),
        .testTarget(
            name: "RudderIntegrationSprigTests",
            dependencies: ["RudderIntegrationSprig"]
        )
    ]
)
