// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoffeeKit",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "CoffeeKit", targets: ["CoffeeKit"])
    ],
    targets: [
        .target(
            name: "CoffeeKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "CoffeeKitTests",
            dependencies: ["CoffeeKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
