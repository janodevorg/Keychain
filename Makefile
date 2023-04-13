#!/bin/bash -e -o pipefail

PROJECT_NAME = Keychain
TARGET_NAME = Keychain
TARGET_NAME_LOWERCASE = keychain
GITHUB_USER = janodevorg

project: #requirexcodegen
	rm -rf "${PROJECT_NAME}.xcodeproj"
	xcodegen generate --project . --spec project.yml
	echo Generated ${PROJECT_NAME}.xcodeproj
	open ${PROJECT_NAME}.xcodeproj

docc: requirejq
	rm -rf docs
	swift build
	DOCC_JSON_PRETTYPRINT=YES
	swift package \
 	--allow-writing-to-directory ./docs \
	generate-documentation \
 	--target ${TARGET_NAME} \
 	--output-path ./docs \
 	--transform-for-static-hosting \
 	--hosting-base-path ${TARGET_NAME} \
	--emit-digest
	cat docs/linkable-entities.json | jq '.[].referenceURL' -r | sort > docs/all_identifiers.txt
	sort docs/all_identifiers.txt | sed -e "s/doc:\/\/${TARGET_NAME}\/documentation\\///g" | sed -e "s/^/- \`\`/g" | sed -e 's/$$/``/g' > docs/all_symbols.txt
	@echo "Check https://${GITHUB_USER}.github.io/${TARGET_NAME}/documentation/${TARGET_NAME_LOWERCASE}/"
	@echo ""

build:
	set -o pipefail && xcodebuild build -scheme "Keychain" -destination "OS=16.4,name=iPhone 14 Pro" -skipPackagePluginValidation | xcbeautify \
    && xcodebuild build -scheme "Keychain" -destination "platform=macOS,arch=arm64" -skipPackagePluginValidation | xcbeautify \
    && xcodebuild build -scheme "Keychain" -destination "platform=macOS,arch=arm64,variant=Mac Catalyst" -skipPackagePluginValidation | xcbeautify \
    && xcodebuild build -scheme "Keychain" -destination "platform=tvOS Simulator,name=Apple TV 4K (3rd generation)" -skipPackagePluginValidation | xcbeautify \
    && cd Example && xcodegen && xcodebuild -scheme Example test -destination "OS=16.4,name=iPhone 14 Pro" -skipPackagePluginValidation | xcbeautify || true && cd ..
