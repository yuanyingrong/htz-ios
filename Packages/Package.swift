// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HTZPackages",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "CoreAudio", targets: ["CoreAudio"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "NetworkKit", targets: ["NetworkKit"]),
        .library(name: "Home", targets: ["Home"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
    ],
    targets: [
        .target(
            name: "CoreAudio",
            dependencies: [],
            path: "CoreAudio/Sources/CoreAudio"
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
    ]
)
