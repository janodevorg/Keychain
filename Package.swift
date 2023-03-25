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
        .library(name: "Keychain", type: .static, targets: ["Keychain"]),
        .library(name: "KeychainDynamic", type: .dynamic, targets: ["Keychain"])
    ],
    dependencies: [
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Keychain",
            dependencies: [
            ],
            path: "sources/main"
        )
    ]
)
