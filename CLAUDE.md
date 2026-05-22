# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Cross-machine shared Claude Code configuration. Keeps plugins, skills, tools, and config files in sync across machines via symlinks.

## Install / Update

```shell
./install          # Fresh install or re-run to pick up changes
git pull && ./install  # Update
```

`install` will:
1. Check deps: `node`, `npx`, `npm`, `http` (HTTPie)
2. Install `claude` CLI if missing
3. Install all Claude plugins via `claude plugin install`
4. Symlink `./skills/*.json` → `~/.claude/skills/`
5. Run any executable `./tools/*.sh` scripts

## Adding things

**New plugin**: add the name to the `plugins` array in `install`.

**New skill**: drop a `.json` file in `skills/`. The install script symlinks it to `~/.claude/skills/` automatically.

**New external tool**: add an executable `.sh` script to `tools/`. Install runs all `tools/*.sh` files.

**New shared config file**: place it in `config/` and add a `ln -s` step to `install` targeting the appropriate `~/.claude/` path.

## Current plugins installed

superpowers, claude-md-management, code-review, code-simplifier, commit-commands, context7, frontend-design, playwright, skill-creator

## External tools managed here

- [rtk](https://github.com/rtk-ai/rtk) — token-optimized Claude Code proxy (`tools/install-rtk`)
- [ccstatusline](https://github.com/sirmalloc/ccstatusline), [happy](https://github.com/slopus/happy), [caveman](https://github.com/juliusbrussee/caveman), [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) — installed separately, not yet scripted here
