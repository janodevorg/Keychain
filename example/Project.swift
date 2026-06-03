import ProjectDescription

let project = Project(
    name: "Example",
    packages: [
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.58.2")
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
        "MACOSX_DEPLOYMENT_TARGET": "26.0",
        "ENABLE_MODULE_VERIFIER": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "23KN7M4FPW"
    ]),
    targets: [
        .target(
            name: "Example",
            destinations: [.iPhone, .mac],
            product: .app,
            bundleId: "dev.jano.apple.example",
            infoPlist: .file(path: "Sources/Info.plist"),
            sources: ["Sources/**"],
            resources: [
                "Sources/Assets.xcassets",
                "Sources/Base.lproj/**"
            ],
            entitlements: "Example.entitlements",
            scripts: [
                swiftlintScript()
            ],
            dependencies: [
                .project(target: "Keychain", path: "../")
            ]
        ),
        .target(
            name: "ExampleTests",
            destinations: [.iPhone, .mac],
            product: .unitTests,
            bundleId: "dev.jano.apple.example.test",
            sources: ["Tests/**"],
            resources: [
            ],
            entitlements: "Example.entitlements",
            dependencies: [
                .target(name: "Example"),
                .project(target: "Keychain", path: "../")
            ],
            additionalFiles: [
                "Project.swift"
            ]
        )
    ],
    schemes: [
       Scheme.scheme(
           name: "Example",
           shared: true,
           buildAction: BuildAction.buildAction(
               targets: [TargetReference.target("Example")]
           ),
           testAction: .testPlans(
               [Path.path("Example.xctestplan")],
               configuration: .debug,
               attachDebugger: true
           )
       )
    ]
)

func swiftlintScript() -> ProjectDescription.TargetScript {
    let script = """
    #!/bin/sh

    # Check swiftlint
    command -v /opt/homebrew/bin/swiftlint >/dev/null 2>&1 || { echo >&2 "swiftlint not found at /opt/homebrew/bin/swiftlint. Aborting."; exit 1; }

    # Create a temp file
    temp_file=$(mktemp)

    # Gather all modified and stopiced files within the Sources directory
    git ls-files -m Sources | grep ".swift$" > "${temp_file}"
    git diff --name-only --cached Sources | grep ".swift$" >> "${temp_file}"

    # Make list of unique and sorterd files
    counter=0
    for f in $(sort "${temp_file}" | uniq)
    do
        eval "export SCRIPT_INPUT_FILE_$counter=$f"
        counter=$(expr $counter + 1)
    done

    # Lint
    if [ $counter -gt 0 ]; then
        export SCRIPT_INPUT_FILE_COUNT=${counter}
        /opt/homebrew/bin/swiftlint autocorrect --use-script-input-files
    fi
    """
    return .post(script: script, name: "Swiftlint", basedOnDependencyAnalysis: false, runForInstallBuildsOnly: false, shellPath: "/bin/zsh")
}
