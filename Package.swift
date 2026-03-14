// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shelf",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.5.0"),
        
        // RevenueCat for subscription management
        .package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.31.0")
    ],
    targets: [
        .target(
            name: "Shelf",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "RevenueCat", package: "purchases-ios")
            ]
        )
    ]
)