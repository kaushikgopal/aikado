# AI-KA(ush)-DO

This repo is the source of truth for Kaush's agent setup: shared instructions,
commands, skills, and tool config.

This setup follows the `AGENTS.md` approach described here:
https://kau.sh/blog/agents-md

## User Setup

For your own machine, run:

```sh
make setup
```

`make setup` is just an alias for `make setup-user`.

That will:

- create a real `~/.agents/` directory and symlink `~/.agents/skills` to this repo
- symlink `~/AGENTS.md` to this repo
- symlink `~/.claude/CLAUDE.md` to this repo
- symlink `aikado/agents` into `~/.claude/agents` and `~/.config/opencode/agents`
- wire Claude, Codex, and OpenCode directly to the repo-owned assets
- symlink shared Claude config from `config/claude/settings.json`

Keep personal or sensitive Claude settings in `~/.claude/settings.local.json`.

## Available Make Commands

To see the built-in targets from the `Makefile`, run:

```sh
make help
```

The main commands are:

- `make setup` - alias for `make setup-user`
- `make setup-user` - sets up the user-level symlinks in your home directory
- `make setup-project dir=/path/to/repo` - initializes agent files in an existing repo
- `make setup-project-here` - initializes the current repo when invoked via this `Makefile`

## Project Setup

To initialize a new repo with project-local agent scaffolding, run:

```sh
make setup-project dir=~/dev/oss/some-repo
```

That creates `AGENTS.md`, `CLAUDE.md`, `.agents/`, and the tool-specific
symlinks used by Claude, Codex, OpenCode, and Gemini.

If you are already inside the target repo, you can also run:

```sh
make -f ~/dev/oss/aikado/Makefile setup-project-here
```

That is equivalent to running `make setup-project dir=.` with this repo's
`Makefile`.
