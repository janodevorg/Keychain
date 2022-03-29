// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Keychain",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "Keychain", type: .dynamic, targets: ["Keychain"]),
        .library(name: "KeychainStatic", type: .static, targets: ["Keychain"])
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
