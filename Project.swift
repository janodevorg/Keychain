import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: name,
    packages: [
    ],
    settings: baseSettings,
    targets: [
        createTarget(
            name,
            destinations: [.iPhone, .iPad, .mac],
            product: .dynamicLibrary,
            dependencies: []
        ),
        .target(
            name: "\(name)Tests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "dev.jano.recallkit.tests",
            infoPlist: .default,
            sources: ["Tests/\(name)Tests/**"],
            resources: [],
            dependencies: [.target(name: name)],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug",
                           settings: [
                            "DEVELOPMENT_TEAM": "PPSF6CNP8Q",
                             "CODE_SIGN_IDENTITY": "Apple Development",
                             "CODE_SIGN_STYLE": "Manual",
                             "PROVISIONING_PROFILE_SPECIFIER": ""
                           ]
                     ),
                    .release(name: "Release",
                           settings: [
                            "DEVELOPMENT_TEAM": "PPSF6CNP8Q",
                             "CODE_SIGN_IDENTITY": "Apple Development",
                             "CODE_SIGN_STYLE": "Manual",
                             "PROVISIONING_PROFILE_SPECIFIER": ""
                           ]
                     )
                ]
            )
        )
    ],
    schemes: [
        createScheme()
    ],
    additionalFiles: [
        "Tests/Configuration/TestKeychain.entitlements",
        "Package.swift",
        "Project.swift",
        "README.md"
    ]
)
