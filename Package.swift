// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "Keychain",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v14),
        .macOS(.v12),
        .tvOS(.v14)
    ],
    products: [
        .library(name: "Keychain", targets: ["Keychain"])
    ],
    dependencies: [
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.0.0")
        // disabled because it creates problems building release versions. Error message: Missing package product 'SwiftLintPlugin@11'
        // .package(url: "git@github.com:realm/SwiftLint.git", from: "0.51.0")
    ],
    targets: [
        .target(
            name: "Keychain",
            path: "Sources/Keychain"
            // plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        )
    ]
)
