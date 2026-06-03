import ProjectDescription

let project = Project(
    name: "Keychain",
    packages: [
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.59.1"),
        .package(url: "git@github.com:apple/swift-docc-plugin.git", from: "1.4.3")
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
            name: "Keychain",
            destinations: [.iPhone, .mac],
            product: .framework,
            bundleId: "dev.jano.keychain",
            sources: ["Sources/Main/**"],
            scripts: [
                swiftlintScript()
            ],
            dependencies: []
        ),
        .target(
            name: "KeychainTests",
            destinations: [.iPhone, .mac],
            product: .unitTests,
            bundleId: "dev.jano.keychain.test",
            sources: ["Sources/Tests/**"],
            entitlements: "Sources/Tests/Configuration/TestKeychain.entitlements",
            dependencies: [
                .target(name: "Keychain"),
                .project(target: "Example", path: "Example")
            ],
            settings: .settings(
                base: [
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Example.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Example"
                ]
            )
        )
    ],
    schemes: [
       Scheme.scheme(
           name: "Keychain",
           shared: true,
           buildAction: BuildAction.buildAction(
               targets: [TargetReference.target("Keychain")]
           ),
           testAction: .targets(
               [TestableTarget.testableTarget(target: TargetReference.target("KeychainTests"))],
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

    # Gather all modified and staged files within the Sources directory
    git ls-files -m Sources | grep ".swift$" > "${temp_file}"
    git diff --name-only --cached Sources | grep ".swift$" >> "${temp_file}"

    # Make list of unique and sorted files
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
