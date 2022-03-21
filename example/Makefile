#!/bin/bash -e -o pipefail

.PHONY: help clean project

help:
	@echo Usage:
	@echo ""
	@echo "  make clean   - removes all generated products"
	@echo "  make project - generates a project with local dependencies"
	@echo ""

project: 
 ifeq (, $(shell which brew))
 	$(error "Error: No brew installed. Install it from https://brew.sh/")
 endif
 ifeq (, $(shell which xcodegen))
 	$(error "Error: No xcodegen installed. Install with: brew install xcodegen")
 endif
	rm -rf Example.xcodeproj || true
	xcodegen generate --project . --spec project.yml && open Example.xcodeproj

clean:
	rm -rf .build
	rm -rf .swiftpm
	rm -rf build
	rm Package.resolved
