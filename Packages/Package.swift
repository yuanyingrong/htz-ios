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
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
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
            path: "DesignSystem/Sources/DesignSystem"
        ),
        .target(
            name: "NetworkKit",
            dependencies: [],
            path: "NetworkKit/Sources/NetworkKit"
        ),
    ]
)
