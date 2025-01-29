import ProjectDescription

/*
Requires this folder structure:

 PROJECT_ROOT
     Sources/<name>
     Configuration/Settings.xcconfig
     Tests/<name>Tests
*/

public let baseSettings: ProjectDescription.Settings = .settings(base: [
    "CODE_SIGN_IDENTITY": "Apple Development",
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "PPSF6CNP8Q",
    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
    "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
    "MACOSX_DEPLOYMENT_TARGET": "15.0",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "6.0"
])

public func createTarget(
    _ name: String,
    destinations: ProjectDescription.Destinations,
    product: ProjectDescription.Product,
    dependencies: [ProjectDescription.TargetDependency] = []
) -> ProjectDescription.Target
{
    if product == .unitTests {
        return createTargetUnitTests(name, destinations: destinations)
    }
    return .target(
        name: name,
        destinations: destinations,
        product: product,
        bundleId: "\(bundleIdentifierPrefix).\(name.lowercased())",
        infoPlist: .extendingDefault(
            with: [
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageName": "",
                ],
                "CFBundleIconName": "AppIcon",
                "CFBundleIcons": [
                    "CFBundlePrimaryIcon": [
                        "CFBundleIconFiles": ["AppIcon"],
                        "CFBundleIconName": "AppIcon"
                    ]
                ]
            ]
        ),
        sources: ["Sources/\(name)/**"],
        resources: ["Sources/\(name)/Resources/**"],
        scripts: [
            buildNumberScript(xcconfigPath: "Sources/Configuration/Settings.xcconfig"),
            swiftlintScript()
        ],
        dependencies: dependencies,
        settings: .settings(
            configurations: [
                .debug(
                    name: "Debug",
                    settings: [:]
                ),
                .release(
                    name: "Release",
                    settings: [
                        "SWIFT_COMPILATION_MODE": "wholemodule"
                    ]
                )
            ]
        )
    )
}

private func createTargetUnitTests(
    _ name: String,
    destinations: ProjectDescription.Destinations
) -> ProjectDescription.Target
{
    .target(
        name: "\(name)Tests",
        destinations: .iOS,
        product: .unitTests,
        bundleId: "\(bundleIdentifierPrefix).\(name.lowercased()).tests",
        infoPlist: .default,
        sources: ["Tests/\(name)Tests/**"],
        resources: [],
        dependencies: [.target(name: name)]
    )
}

public func swiftlintScript() -> ProjectDescription.TargetScript {
    let script = """
    #!/bin/sh

    ### COPY CONFIG

    # 1. Figure out the root Derived Data path by going up from $PROJECT_TEMP_DIR
    DERIVED_DATA_DIR="$(cd "$PROJECT_TEMP_DIR"/../../.. && pwd)"
    echo "Derived Data directory is: $DERIVED_DATA_DIR"

    # 2. Paths to your SwiftLint config files in the project folder
    SOURCE_FILE_MAIN="$SRCROOT/.swiftlint.yml"
    SOURCE_FILE_CHILD="$SRCROOT/.swiftlint-refinement.yml"

    # 3. Copy both files into Derived Data
    #    (You'll only copy what's actually there—if either is missing, it logs a warning.)
    for FILE in "$SOURCE_FILE_MAIN" "$SOURCE_FILE_CHILD"; do
      BASENAME=$(basename "$FILE")
      if [ -f "$FILE" ]; then
        cp "$FILE" "$DERIVED_DATA_DIR/$BASENAME"
        echo "Copied $BASENAME to $DERIVED_DATA_DIR"
      else
        echo "warning: $FILE not found. Skipping."
      fi
    done

    ### RUN SWIFTLINT

    ###
    # 1. Determine SwiftLint path with fallback
    ###
    SWIFTLINT="/opt/homebrew/bin/swiftlint"
    if ! command -v "$SWIFTLINT" >/dev/null 2>&1; then
      if ! command -v swiftlint >/dev/null 2>&1; then
        echo "error: SwiftLint not found. Install it via Homebrew or https://github.com/realm/SwiftLint"
        exit 1
      else
        SWIFTLINT="swiftlint"
      fi
    fi

    ###
    # 2. Path to SwiftLint config
    #    Adjust if your .swiftlint.yml is in a different location.
    ###
    CONFIG_FILE=".swiftlint.yml"
    if [ ! -f "$CONFIG_FILE" ]; then
      echo "warning: $CONFIG_FILE not found, continuing without explicit config."
      CONFIG_FILE=""
    fi

    ###
    # 3. Create temp file and set trap to remove it
    ###
    temp_file=$(mktemp)
    trap 'rm -f "$temp_file"' EXIT

    ###
    # 4. Gather changed, staged, or untracked Swift files in Sources/
    ###
    git status --porcelain \
      | grep -E '^(M|A|\\?\\?) ' \
      | awk '{print $2}' \
      | grep '^Sources/.*\\.swift$' \
      > "$temp_file"

    ###
    # 5. Export files as SCRIPT_INPUT_FILE_x so SwiftLint can use --use-script-input-files
    ###
    counter=0
    while read -r file; do
      # Sort and uniq are omitted in the while loop approach because we’re reading line by line.
      # If you want them, add an extra step to filter duplicates:
      #   sort "$temp_file" | uniq | while read -r file; do ...
      if [ -n "$file" ]; then
        eval "export SCRIPT_INPUT_FILE_$counter=\"$file\""
        counter=$((counter + 1))
      fi
    done < "$temp_file"

    if [ $counter -gt 0 ]; then
      export SCRIPT_INPUT_FILE_COUNT="$counter"
      
      if [ -n "$CONFIG_FILE" ]; then
        "$SWIFTLINT" autocorrect --config "$CONFIG_FILE" --use-script-input-files
      else
        "$SWIFTLINT" autocorrect --use-script-input-files
      fi
    fi
    """
    return .post(script: script, name: "Swiftlint", basedOnDependencyAnalysis: false, runForInstallBuildsOnly: false, shellPath: "/bin/zsh")
}

/// Sets the build number to the number of commits of the main branch.
/// The build number is set in the passed xcconfig file.
/// This script only executes for Release configurations.
public func buildNumberScript(xcconfigPath: String) -> ProjectDescription.TargetScript {
    let script = """
    #!/bin/sh

    if [ "${CONFIGURATION}" = "Release" ]; then
        configFile="\(xcconfigPath)"

        if ! command -v git > /dev/null 2>&1
        then
            echo "git command not found, aborting."
            exit 1
        fi

        if [ ! -f "$configFile" ]; then
            echo "Config file does not exist: $configFile"
            exit 1
        fi

        # Read the current project version
        currentVersion=$(grep 'CURRENT_PROJECT_VERSION = ' "$configFile" | cut -d ' ' -f 3)

        # Determine the number of commits on the main branch
        commitCount=$(git rev-list --count main)

        if [ "$currentVersion" -eq "$commitCount" ]; then
            echo "Build number didn’t change: $currentVersion"
        else
            # Update build version to the number of commits
            sed -i '' "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $commitCount/" "$configFile"
            echo "Build number incremented from $currentVersion to $commitCount"
        fi
    fi

    """
    return .pre(script: script, name: "Set build number", basedOnDependencyAnalysis: false, runForInstallBuildsOnly: false, shellPath: "/bin/sh")
}

// MARK: - Scheme

public func createScheme() -> Scheme {
    .scheme(
        name: name,
        shared: true,
        buildAction: BuildAction.buildAction(
            targets: [TargetReference.target(name)]
        ),
        // testAction: .testPlans(
        //     [Path.path("Sources/UIKit/TestPlan.xctestplan")],
        //     configuration: .debug,
        //     attachDebugger: true
        // ),
        runAction: RunAction.runAction(
            configuration: .debug,
            executable: TargetReference.target(name),
            arguments: .arguments(
                environmentVariables: [:],
                launchArguments: [
                    ProjectDescription.LaunchArgument.launchArgument(name: "-com.apple.CoreData.SQLDebug 1", isEnabled: true),
                    ProjectDescription.LaunchArgument.launchArgument(name: "-com.apple.CoreData.Logging.stderr 0", isEnabled: true),
                    ProjectDescription.LaunchArgument.launchArgument(name: "-com.apple.CoreData.ConcurrencyDebug 1", isEnabled: true)
                ]
            ),
            options: .options(language: SchemeLanguage(identifier: "es"))
        )
    )
}

public func dynamicLibrary_iOS_macOS() -> Project {
    Project(
        name: name,
        settings: baseSettings,
        targets: [
            createTarget(
                name,
                destinations: [.iPhone, .iPad, .mac],
                product: .dynamicLibrary
            ),
            createTarget(
                name,
                destinations: [.iPhone, .iPad, .mac],
                product: .unitTests
            )
        ],
        schemes: [
            createScheme()
        ]
    )
}
