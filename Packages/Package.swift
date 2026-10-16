// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HTZPackages",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "HTZAudio", targets: ["HTZAudio"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "NetworkKit", targets: ["NetworkKit"]),
        .library(name: "Home", targets: ["Home"]),
        .library(name: "PlayerFeature", targets: ["PlayerFeature"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
    ],
    targets: [
        .target(
            name: "HTZAudio",
            dependencies: [],
            path: "HTZAudio/Sources/HTZAudio"
        ),
        .target(
            name: "PlayerFeature",
            dependencies: [
                "HTZAudio",
                "DesignSystem",
                "NetworkKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Features/Player/Sources/PlayerFeature"
        ),
        .target(
            name: "DesignSystem",
            dependencies: [],
            path: "DesignSystem/Sources/DesignSystem",
            resources: [.process("Resources")]
        ),
        .target(
            name: "NetworkKit",
            dependencies: [
                .product(name: "Moya", package: "Moya"),
                .product(name: "CombineMoya", package: "Moya"),
            ],
            path: "NetworkKit/Sources/NetworkKit"
        ),
        .target(
            name: "Home",
            dependencies: [
                "NetworkKit",
                "DesignSystem",
                "HTZAudio",
                "PlayerFeature", // Add PlayerFeature dependency
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Features/Home/Sources/Home"
        ),
        .testTarget(
            name: "NetworkKitTests",
            dependencies: ["NetworkKit"],
            path: "NetworkKit/Tests/NetworkKitTests"
        ),
        .testTarget(
            name: "HomeTests",
            dependencies: ["Home"],
            path: "Features/Home/Tests/HomeTests"
        ),
        .target(
            name: "AuthFeature",
            dependencies: [
                "NetworkKit",
                "DesignSystem",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Features/Auth/Sources/AuthFeature"
        ),
        .testTarget(
            name: "AuthTests",
            dependencies: ["AuthFeature"],
            path: "Features/Auth/Tests/AuthTests"
        ),
        .testTarget(
            name: "PlayerFeatureTests",
            dependencies: ["PlayerFeature"],
            path: "Features/Player/Tests/PlayerFeatureTests"
        ),
    ]
)
