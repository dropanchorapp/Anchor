# Makefile for Anchor Project
# Swift project with multiple targets: macOS menu bar app, iOS mobile app, and shared AnchorKit library

.PHONY: help lint lint-fix lint-strict test test-swift test-ui build clean setup check info

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# SwiftLint Commands
lint: ## Run SwiftLint to check for style and syntax issues
	@echo "🔍 Running SwiftLint..."
	swiftlint

lint-fix: ## Run SwiftLint with automatic fixes
	@echo "🔧 Running SwiftLint with automatic fixes..."
	swiftlint --fix

lint-strict: ## Run SwiftLint in strict mode (treat warnings as errors)
	@echo "🔍 Running SwiftLint in strict mode..."
	swiftlint --strict

# Testing Commands
test: test-swift ## Run all tests (currently just Swift package tests)

test-swift: ## Run AnchorKit Swift package tests
	@echo "🧪 Running AnchorKit tests..."
	cd AnchorKit && swift test

test-ui: ## Run Xcode project tests (AnchorMobile - currently placeholder tests)
	@echo "🧪 Running AnchorMobile iOS tests..."
	xcodebuild test -project Anchor.xcodeproj -scheme AnchorMobile -destination 'platform=iOS Simulator,name=iPhone 16'

build: ## Build AnchorMobile iOS app
	@echo "🏗️ Building AnchorMobile iOS app..."
	xcodebuild build -project Anchor.xcodeproj -scheme AnchorMobile -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug

# Development Commands
clean: ## Clean all build artifacts
	@echo "🧹 Cleaning build artifacts..."
	xcodebuild clean -project Anchor.xcodeproj
	cd AnchorKit && swift package clean
	rm -rf build/
	rm -rf .build/
	rm -rf AnchorKit/.build/
	rm -rf ~/Library/Developer/Xcode/DerivedData

# Quality Assurance Commands
check: lint-fix lint test-swift ## Run quality assurance checks (lint + test)

# Info Commands
info: ## Show project information
	@echo "📊 Anchor Project Information"
	@echo "=============================="
	@echo "Swift Version: $$(swift --version | head -n1)"
	@echo "Xcode Version: $$(xcodebuild -version | head -n1)"
	@echo "SwiftLint Version: $$(swiftlint --version 2>/dev/null || echo 'Not installed')"
	@echo ""
	@echo "Project Structure:"
	@echo "- AnchorMobile (iOS mobile app)"  
	@echo "- AnchorKit (shared Swift package)"
	@echo ""
	@echo "Available simulators:"
	@xcrun simctl list devices available | grep -E 'iPhone|iPad' | head -5
