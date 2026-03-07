ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
dir ?=

.PHONY: help setup setup-user setup-project setup-project-here

help:
	@printf "Targets:\n"
	@printf "  make setup-user\n"
	@printf "  make setup-project dir=/path/to/repo\n"
	@printf "  make setup-project-here  # run from target repo with: make -f ~/dev/oss/aikado/Makefile setup-project-here\n"

setup: setup-user

setup-user:
	@printf "setting up agent symlinks\n"
	@if [ -L "$(HOME)/.ai" ] || [ -e "$(HOME)/.ai" ]; then \
		rm -rf "$(HOME)/.ai"; \
	fi
	@rm -rf "$(HOME)/.agents"
	@ln -sfn "$(ROOT)" "$(HOME)/.agents"
	@mkdir -p "$(HOME)/.config/opencode"
	@ln -sfn "$(ROOT)/config/opencode/opencode.json" "$(HOME)/.config/opencode/opencode.json"
	@ln -sfn "$(ROOT)/config/opencode/tui.json" "$(HOME)/.config/opencode/tui.json"
	@rm -rf "$(HOME)/.config/opencode/plugins"
	@ln -sfn "$(ROOT)/config/opencode/plugins" "$(HOME)/.config/opencode/plugins"
	@rm -rf "$(HOME)/.config/opencode/themes"
	@ln -sfn "$(ROOT)/config/opencode/themes" "$(HOME)/.config/opencode/themes"
	@if [ -L "$(HOME)/.claude" ]; then \
		rm "$(HOME)/.claude"; \
	fi
	@mkdir -p "$(HOME)/.claude"
	@ln -sfn "$(HOME)/.agents/AGENTS.md" "$(HOME)/.claude/CLAUDE.md"
	@rm -rf "$(HOME)/.claude/commands"
	@ln -sfn "$(HOME)/.agents/commands" "$(HOME)/.claude/commands"
	@rm -rf "$(HOME)/.claude/skills"
	@ln -sfn "$(HOME)/.agents/skills" "$(HOME)/.claude/skills"
	@ln -sfn "$(ROOT)/config/claude/settings.json" "$(HOME)/.claude/settings.json"
	@ln -sfn "$(ROOT)/config/claude/statusline.sh" "$(HOME)/.claude/statusline.sh"
	@rm -rf "$(HOME)/.claude/hooks"
	@ln -sfn "$(ROOT)/config/claude/hooks" "$(HOME)/.claude/hooks"
	@mkdir -p "$(HOME)/.codex"
	@rm -rf "$(HOME)/.codex/prompts"
	@ln -sfn "$(HOME)/.agents/commands" "$(HOME)/.codex/prompts"
	@ln -sfn "$(HOME)/.agents/AGENTS.md" "$(HOME)/.codex/AGENTS.md"
	@printf "agent setup complete\n"

setup-project:
	@if [ -z "$(dir)" ]; then \
		printf "usage: make setup-project dir=/path/to/repo\n"; \
		exit 1; \
	fi
	@project_dir="$$(cd "$(dir)" && pwd)"; \
	printf "setting up agent structure in %s\n" "$$project_dir"; \
	if [ ! -f "$$project_dir/AGENTS.md" ]; then \
		touch "$$project_dir/AGENTS.md"; \
	fi; \
	if [ ! -f "$$project_dir/CLAUDE.md" ]; then \
		printf "See @AGENTS.md\n" > "$$project_dir/CLAUDE.md"; \
	fi; \
	mkdir -p \
		"$$project_dir/.agents/skills" \
		"$$project_dir/.agents/commands" \
		"$$project_dir/.agents/plans" \
		"$$project_dir/.agents/tmp" \
		"$$project_dir/.claude" \
		"$$project_dir/.codex" \
		"$$project_dir/.opencode" \
		"$$project_dir/.gemini"; \
	rm -rf "$$project_dir/.claude/commands"; \
	ln -sfn ../.agents/commands "$$project_dir/.claude/commands"; \
	rm -rf "$$project_dir/.claude/skills"; \
	ln -sfn ../.agents/skills "$$project_dir/.claude/skills"; \
	rm -rf "$$project_dir/.codex/prompts"; \
	ln -sfn ../.agents/commands "$$project_dir/.codex/prompts"; \
	printf '{"context":{"fileName":["AGENTS.md"]}}\n' > "$$project_dir/.gemini/settings.json"; \
	if ! grep -qxF ".agents/tmp/**" "$$project_dir/.gitignore" 2>/dev/null; then \
		printf ".agents/tmp/**\n" >> "$$project_dir/.gitignore"; \
	fi; \
	printf "agent project setup complete in %s\n" "$$project_dir"

# Run this target from inside the repo you want to initialize:
#   cd ~/dev/oss/project-xxx
#   make -f ~/dev/oss/aikado/Makefile setup-project-here
setup-project-here:
	@$(MAKE) setup-project dir=.
