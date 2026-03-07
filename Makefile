ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
dir ?=
GRAY := \033[1;30m
NC := \033[0m

.PHONY: help setup setup-user setup-project setup-project-here

help:
	@printf "%b\n" "$(GRAY)Targets:$(NC)"
	@printf "%b\n" "$(GRAY)  make setup-user$(NC)"
	@printf "%b\n" "$(GRAY)  make setup-project dir=/path/to/repo$(NC)"
	@printf "%b\n" "$(GRAY)  make setup-project-here  # run from target repo with: make -f ~/dev/oss/aikado/Makefile setup-project-here$(NC)"

setup: setup-user

setup-user:
	@printf "%b\n" "$(GRAY)••••••• setting up agent symlinks$(NC)"

	@# legacy cleanup
	@if [ -L "$(HOME)/.ai" ] || [ -e "$(HOME)/.ai" ]; then \
		printf "%b\n" "$(GRAY)••••••• removing legacy $(HOME)/.ai$(NC)"; \
		rm -rf "$(HOME)/.ai"; \
	fi
	@if [ -L "$(HOME)/.agents" ]; then \
		printf "%b\n" "$(GRAY)••••••• removing legacy $(HOME)/.agents symlink$(NC)"; \
		rm "$(HOME)/.agents"; \
	fi

	@# global agent paths
	@mkdir -p "$(HOME)/.agents"
	@ln -sfn "$(ROOT)/skills" "$(HOME)/.agents/skills"
	@ln -sfn "$(ROOT)/AGENTS.md" "$(HOME)/AGENTS.md"
	@printf "%b\n" "$(GRAY)••••••• symlinked $(ROOT)/AGENTS.md -> $(HOME)/AGENTS.md$(NC)"
	@printf "%b\n" "$(GRAY)••••••• symlinked $(ROOT)/skills -> $(HOME)/.agents/skills$(NC)"

	@# opencode
	@mkdir -p "$(HOME)/.config/opencode"
	@ln -sfn "$(ROOT)/config/opencode/opencode.json" "$(HOME)/.config/opencode/opencode.json"
	@ln -sfn "$(ROOT)/config/opencode/tui.json" "$(HOME)/.config/opencode/tui.json"
	@rm -rf "$(HOME)/.config/opencode/agents"
	@ln -sfn "$(ROOT)/agents" "$(HOME)/.config/opencode/agents"
	@rm -rf "$(HOME)/.config/opencode/plugins"
	@ln -sfn "$(ROOT)/config/opencode/plugins" "$(HOME)/.config/opencode/plugins"
	@rm -rf "$(HOME)/.config/opencode/themes"
	@ln -sfn "$(ROOT)/config/opencode/themes" "$(HOME)/.config/opencode/themes"

	@# claude
	@if [ -L "$(HOME)/.claude" ]; then \
		printf "%b\n" "$(GRAY)••••••• removing legacy $(HOME)/.claude symlink$(NC)"; \
		rm "$(HOME)/.claude"; \
	fi
	@mkdir -p "$(HOME)/.claude"
	@ln -sfn "$(ROOT)/CLAUDE.md" "$(HOME)/.claude/CLAUDE.md"
	@printf "%b\n" "$(GRAY)••••••• symlinked $(ROOT)/CLAUDE.md -> $(HOME)/.claude/CLAUDE.md$(NC)"
	@rm -rf "$(HOME)/.claude/agents"
	@ln -sfn "$(ROOT)/agents" "$(HOME)/.claude/agents"
	@rm -rf "$(HOME)/.claude/commands"
	@ln -sfn "$(ROOT)/commands" "$(HOME)/.claude/commands"
	@rm -rf "$(HOME)/.claude/skills"
	@ln -sfn "$(ROOT)/skills" "$(HOME)/.claude/skills"
	@ln -sfn "$(ROOT)/config/claude/settings.json" "$(HOME)/.claude/settings.json"
	@ln -sfn "$(ROOT)/config/claude/statusline.sh" "$(HOME)/.claude/statusline.sh"
	@rm -rf "$(HOME)/.claude/hooks"
	@ln -sfn "$(ROOT)/config/claude/hooks" "$(HOME)/.claude/hooks"

	@# codex
	@mkdir -p "$(HOME)/.codex"
	@rm -rf "$(HOME)/.codex/prompts"
	@ln -sfn "$(ROOT)/commands" "$(HOME)/.codex/prompts"
	@ln -sfn "$(ROOT)/AGENTS.md" "$(HOME)/.codex/AGENTS.md"
	@printf "%b\n" "$(GRAY)••••••• agent setup complete$(NC)"

setup-project:
	@if [ -z "$(dir)" ]; then \
		printf "%b\n" "$(GRAY)usage: make setup-project dir=/path/to/repo$(NC)"; \
		exit 1; \
	fi
	@project_input='$(dir)'; \
	case "$$project_input" in \
		~) project_input="$$HOME" ;; \
		~/*) project_input="$$HOME/$${project_input#~/}" ;; \
	esac; \
	project_dir="$$(cd "$$project_input" && pwd)"; \
	printf "%b\n" "$(GRAY)••••••• setting up agent structure in $$project_dir $(NC)"; \
	: "root instruction files"; \
	if [ ! -f "$$project_dir/AGENTS.md" ]; then \
		touch "$$project_dir/AGENTS.md"; \
		printf "%b\n" "$(GRAY)••••••• created AGENTS.md $(NC)"; \
	fi; \
	if [ ! -f "$$project_dir/CLAUDE.md" ]; then \
		printf "See @AGENTS.md\n" > "$$project_dir/CLAUDE.md"; \
		printf "%b\n" "$(GRAY)••••••• created CLAUDE.md -> @AGENTS.md $(NC)"; \
	fi; \
	: "project agent directories"; \
	mkdir -p \
		"$$project_dir/.agents/skills" \
		"$$project_dir/.agents/commands" \
		"$$project_dir/.agents/plans" \
		"$$project_dir/.agents/tmp" \
		"$$project_dir/.claude" \
		"$$project_dir/.codex" \
		"$$project_dir/.opencode" \
		"$$project_dir/.gemini"; \
	: "tool-specific links"; \
	rm -rf "$$project_dir/.claude/commands"; \
	ln -sfn ../.agents/commands "$$project_dir/.claude/commands"; \
	rm -rf "$$project_dir/.claude/skills"; \
	ln -sfn ../.agents/skills "$$project_dir/.claude/skills"; \
	rm -rf "$$project_dir/.codex/prompts"; \
	ln -sfn ../.agents/commands "$$project_dir/.codex/prompts"; \
	printf '{"context":{"fileName":["AGENTS.md"]}}\n' > "$$project_dir/.gemini/settings.json"; \
	: "gitignore entries"; \
	if ! grep -qxF ".agents/tmp/**" "$$project_dir/.gitignore" 2>/dev/null; then \
		printf ".agents/tmp/**\n" >> "$$project_dir/.gitignore"; \
		printf "%b\n" "$(GRAY)••••••• added .agents/tmp/** to .gitignore $(NC)"; \
	fi; \
	printf "%b\n" "$(GRAY)••••••• agent project setup complete in $$project_dir $(NC)"

# Run this target from inside the repo you want to initialize:
#   cd ~/dev/oss/project-xxx
#   make -f ~/dev/oss/aikado/Makefile setup-project-here
setup-project-here:
	@$(MAKE) setup-project dir=.
