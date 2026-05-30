.DEFAULT_GOAL := help

# Where the generated scaffold lands. Override with TARGET=other-name.
TARGET ?= project-scaffolding
SHARED := templates/_shared

.PHONY: help swift ts clean _ensure-empty _instructions

help: ## Show this help.
	@printf "Default Agent Stack — scaffold generator\n\n"
	@printf "Run one of the targets below, then move ./$(TARGET)/ into your project.\n"
	@printf "The generator refuses to run if ./$(TARGET)/ is not empty.\n\n"
	@printf "Targets:\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;32m%-12s\033[0m %s\n", $$1, $$2}'

MERGE_SETTINGS := jq -s '.[0] * {permissions: {allow: ((.[0].permissions.allow + (.[1].permissions.allow // [])) | unique), deny: ((.[0].permissions.deny + (.[1].permissions.deny // [])) | unique)}, hooks: ((.[0].hooks // {}) * (.[1].hooks // {}))}'

swift: _ensure-empty ## Generate scaffold for a strict Swift 6 / SwiftUI / Xcode project.
	@cp -R $(SHARED)/. $(TARGET)/
	@cp -R templates/swift-ios/. $(TARGET)/
	@$(MERGE_SETTINGS) $(TARGET)/.claude/settings.json $(TARGET)/settings.append.json > $(TARGET)/.claude/settings.json.tmp && mv $(TARGET)/.claude/settings.json.tmp $(TARGET)/.claude/settings.json
	@cat $(TARGET)/gitignore.append >> $(TARGET)/.gitignore
	@rm $(TARGET)/settings.append.json $(TARGET)/gitignore.append
	@$(MAKE) --no-print-directory _instructions

ts: _ensure-empty ## Generate scaffold for a strict TypeScript / Node / Hono / React / Vite / Vitest project.
	@cp -R $(SHARED)/. $(TARGET)/
	@cp -R templates/ts-node-react/. $(TARGET)/
	@$(MERGE_SETTINGS) $(TARGET)/.claude/settings.json $(TARGET)/settings.append.json > $(TARGET)/.claude/settings.json.tmp && mv $(TARGET)/.claude/settings.json.tmp $(TARGET)/.claude/settings.json
	@cat $(TARGET)/gitignore.append >> $(TARGET)/.gitignore
	@rm $(TARGET)/settings.append.json $(TARGET)/gitignore.append
	@$(MAKE) --no-print-directory _instructions

clean: ## Remove the generated scaffold directory entirely.
	@rm -rf $(TARGET)

_ensure-empty:
	@command -v jq >/dev/null 2>&1 || { printf "\033[0;31mERROR:\033[0m \`jq\` is required (it is also used by .claude/settings.json hooks at runtime).\nInstall it: \033[0;33mbrew install jq\033[0m\n" >&2; exit 1; }
	@if [ -d $(TARGET) ] && [ -n "$$(ls -A $(TARGET) 2>/dev/null)" ]; then \
		printf "\033[0;31mERROR:\033[0m ./$(TARGET)/ is not empty.\n" >&2; \
		printf "Move its contents into your project first, or run \`make clean\`.\n" >&2; \
		exit 1; \
	fi
	@mkdir -p $(TARGET)

_instructions:
	@printf "\n\033[0;32m✓ Scaffold ready in ./$(TARGET)/\033[0m\n\n"
	@printf "Move it into your project:\n\n"
	@printf "  \033[0;33mmv $(TARGET)/* $(TARGET)/.* /path/to/your-project/\033[0m\n\n"
	@printf "Then fill \033[0;33mVISION.md\033[0m + \033[0;33mSTACK.md\033[0m, open a few GitHub issues as your backlog,\n"
	@printf "and run \033[0;33mclaude\033[0m → \033[0;33m/project-manager solve issue #1\033[0m (or describe a problem directly).\n\n"
