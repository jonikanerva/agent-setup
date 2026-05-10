# Swift 6 / SwiftUI / Xcode build & test makefile.
#
# This is the single source of truth for verify / lint / build / test commands.
# Agents and CI run named `make` targets — never raw `swift-format` or
# `xcodebuild` invocations.

PROJECT       ?= App.xcodeproj
SCHEME        ?= App
DESTINATION   ?= platform=iOS Simulator,name=iPhone 16,OS=latest
DERIVED_DATA  ?= build/DerivedData
SWIFT_FORMAT  ?= swift-format

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m

.PHONY: help format lint build test test-all test-full clean

help: ## Show this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-12s$(NC) %s\n", $$1, $$2}'

format: ## Auto-format every Swift file in-place.
	@printf "$(YELLOW)→ format$(NC)\n"
	@$(SWIFT_FORMAT) format --in-place --recursive --configuration .swift-format .

lint: ## Lint without modifying files. Fails on any diagnostic.
	@printf "$(YELLOW)→ lint$(NC)\n"
	@$(SWIFT_FORMAT) lint --strict --recursive --configuration .swift-format .

build: ## Build for testing on the configured destination.
	@printf "$(YELLOW)→ build$(NC)\n"
	@xcodebuild build-for-testing \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-quiet

test: ## Run unit tests using the previously built test bundle.
	@printf "$(YELLOW)→ test$(NC)\n"
	@xcodebuild test-without-building \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-only-testing:AppTests \
		-quiet

test-all: lint build test ## Quick PR gate: lint + build + unit tests.
	@printf "$(GREEN)✓ test-all green$(NC)\n"

test-full: lint build ## Nightly / release gate: lint + build + unit + UI tests.
	@xcodebuild test-without-building \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-quiet
	@printf "$(GREEN)✓ test-full green$(NC)\n"

clean: ## Remove derived data.
	@rm -rf "$(DERIVED_DATA)"
	@printf "$(GREEN)✓ cleaned$(NC)\n"
