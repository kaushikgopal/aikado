# AI-KA(ush)-DO

This repo is the source of truth for Kaush's agent setup: shared instructions,
commands, skills, and tool config.

## User Setup

Run:

```sh
make setup
```

That will:

- symlink `~/.agents` to this repo
- wire Claude, Codex, and OpenCode to the repo-owned assets
- symlink shared Claude config from `config/claude/settings.json`

Keep personal or sensitive Claude settings in `~/.claude/settings.local.json`.

## Project Setup

To initialize a new repo with project-local agent scaffolding, run:

```sh
make setup-project dir=~/dev/oss/some-repo
```

That creates `AGENTS.md`, `CLAUDE.md`, `.agents/`, and the tool-specific
symlinks used by Claude, Codex, OpenCode, and Gemini.
