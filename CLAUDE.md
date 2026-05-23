# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Cross-machine shared Claude Code configuration. `./install` bootstraps a new machine. `./update` syncs after `git pull`. `./uninstall` removes everything.

## Install / Update / Uninstall

```shell
./install          # Fresh install or re-run to pick up changes
./update           # git pull + legacy cleanup + re-run install
./uninstall        # Remove all tools, symlinks, and claude entirely
```

## How config is deployed

Files in `config/` are **symlinked** to `~/.claude/` by `./install`. Edits to the repo files take effect immediately. Hooks in `config/hooks/` are symlinked as individual files into `~/.claude/hooks/` (not the whole dir — tool-managed hooks live there independently).

`agents/` and `memory/` are symlinked as whole directories.

## Plugin tracking

Plugins are tracked in `config/settings.json` → `enabledPlugins`. When you install a plugin via the Claude CLI, `settings.json` updates automatically (via symlink). Commit and push to sync to other machines. `./install` re-runs `claude plugin install` for any plugins not yet installed.

**To remove a plugin:** delete it from `enabledPlugins`, add a `legacy/uninstall-plugin-<name>` script containing `claude plugin uninstall <name>`, commit.

## Adding things

| What | How |
|------|-----|
| New plugin | Install via CLI (auto-tracked in settings.json) or add to `enabledPlugins` directly |
| New skill | Drop `.md` in `skills/` |
| New global agent | Drop `.md` in `agents/` |
| New external tool | Add `tools/install-<name>` + `tools/uninstall-<name>` (executable) |
| New custom hook | Add to `hooks/`, register in `config/settings.json` |
| Deprecate a tool | Delete `tools/install-<name>`, move `tools/uninstall-<name>` → `legacy/uninstall-<name>` |

## Security

**Do not add secrets to `config/settings.json` env block** — this file is committed to git.

For per-machine secrets (GitHub PATs, API tokens): add them to `config/env.local` (gitignored, created by `./install`). This file is not auto-sourced — export the vars in your shell profile or source it manually before launching Claude. A template is at `config/env.local.example`.

Use the `secrets-check` skill before committing to verify staged changes contain no credentials.

## External tools

| Tool | Purpose |
|------|---------|
| [rtk](https://github.com/rtk-ai/rtk) | Token-optimised Claude CLI proxy |
| [ccstatusline](https://github.com/sirmalloc/ccstatusline) | Status line (managed via `statusLine` in settings.json, no install script) |
| [happy](https://github.com/slopus/happy) | Mobile/web client for Claude Code |
| [caveman](https://github.com/JuliusBrussee/caveman) | Token-efficient mode (also a Claude plugin) |
| [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) | Code knowledge graph MCP server |
