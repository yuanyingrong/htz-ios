// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlayerFeature",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "PlayerFeature", targets: ["PlayerFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
        .package(path: "../../HTZAudio"), // Dependency on our local HTZAudio
    ],
    targets: [
        .target(
            name: "PlayerFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "HTZAudio", package: "HTZAudio"), // Link to HTZAudio
            ],
            path: "Sources/PlayerFeature"
        ),
        .testTarget(
            name: "PlayerFeatureTests",
            dependencies: ["PlayerFeature"],
            path: "Tests/PlayerFeatureTests"
        ),
    ]
)
