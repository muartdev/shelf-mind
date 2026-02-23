// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MindShelf",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MindShelfCore",
            targets: ["MindShelfCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        // Pure Foundation utilities — no SwiftUI/SwiftData/StoreKit
        .target(
            name: "MindShelfCore",
            dependencies: [],
            path: "Sources/MindShelfCore"
        ),
        .testTarget(
            name: "MindShelfCoreTests",
            dependencies: ["MindShelfCore"],
            path: "Tests/MindShelfCoreTests"
        )
    ]
)
