// swift-tools-version:6.2
@preconcurrency import PackageDescription

let name = "Keychain"

let package = Package(
    name: name,
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: name, targets: [name])
    ],
    dependencies: [
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.4.3")
        // disabled because it creates problems building release versions. Error message: Missing package product 'SwiftLintPlugin@11'
        // .package(url: "git@github.com:realm/SwiftLint.git", from: "0.51.0")
    ],
    targets: [
        .target(
            name: name,
            dependencies: [],
            path: "Sources/Main"
        ),
        .testTarget(
            name: "\(name)Tests",
            dependencies: [Target.Dependency(stringLiteral: name)],
            path: "Sources/Tests",
            exclude: ["Configuration/"]
        )
    ]
)
