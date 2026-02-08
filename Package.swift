// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MindShelf",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MindShelf",
            targets: ["MindShelf"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "MindShelf",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        )
    ]
)
