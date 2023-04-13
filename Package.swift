// swift-tools-version:5.6
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
        .library(name: "Keychain", type: .dynamic, targets: ["Keychain"]),
        .library(name: "KeychainStatic", type: .static, targets: ["Keychain"]),
    ],
    dependencies: [
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.0.0"),
        .package(url: "git@github.com:realm/SwiftLint.git", from: "0.51.0")
    ],
    targets: [
        .target(
            name: "Keychain",
            path: "Sources/Keychain",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        )
    ]
)
