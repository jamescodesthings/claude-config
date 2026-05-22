# Claude Config Repo Redesign

**Date:** 2026-05-22  
**Status:** Approved

## Overview

Transform the claude-config repo into a complete, one-stop bootstrap for Claude Code on a new machine. `./install` produces a fully configured Claude Code environment. `./update` syncs after `git pull`. `./uninstall` cleanly removes everything.

---

## Repo Structure

```
claude-config/
├── install                        # Bootstrap orchestrator
├── update                         # Sync after git pull
├── uninstall                      # Full removal (no prompts)
├── CLAUDE.md
├── readme.md
├── config/                        # Files/dirs symlinked to ~/.claude/
│   ├── CLAUDE.md                  → ~/.claude/CLAUDE.md
│   ├── RTK.md                     → ~/.claude/RTK.md
│   ├── settings.json              → ~/.claude/settings.json  ⚠️ no secrets
│   ├── keybindings.json           → ~/.claude/keybindings.json
│   ├── hooks/                     individual files symlinked into ~/.claude/hooks/
│   └── git-hooks/                 installed to .git/hooks/ (repo-local)
├── agents/                        → ~/.claude/agents/ (global subagents)
├── skills/                        → ~/.claude/skills/ (custom skills)
├── memory/                        → ~/.claude/projects/<computed-path>/memory/
├── legacy/                        # Uninstall scripts for deprecated tools/plugins
│   └── uninstall-*
└── tools/                         # One install-* + uninstall-* per external tool
    ├── install-rtk
    ├── install-ccstatusline
    ├── install-happy
    ├── install-caveman
    ├── install-codebase-memory-mcp
    ├── uninstall-rtk
    ├── uninstall-ccstatusline
    ├── uninstall-happy
    ├── uninstall-caveman
    └── uninstall-codebase-memory-mcp
```

**Gitignore additions:** `.last-update`, `.claude-config-dir`

---

## Code Style

All scripts follow zsh-config conventions:

- Shebang: `#!/usr/bin/env zsh`
- Script-relative paths: `SOURCE_DIR=${0:a:h}`
- Inline color helpers: `info()`, `success()`, `warn()`, `error()` using ANSI codes
- Idempotent symlink pattern:
  ```zsh
  [[ -L $DEST ]] && rm $DEST
  [[ -e $DEST && ! -L $DEST ]] && mv $DEST $DEST.bak  # back up real files
  ln -s $SRC $DEST
  ```
- UPPER_CASE for constants
- `local` keyword only inside functions (fixes existing top-level bug)
- Dependency checks: `command -v <tool> &> /dev/null`

---

## `install` Script

Steps (in order):

1. Check dependencies: `node`, `npx`, `npm`, `http` (HTTPie)
2. Install `claude` CLI if missing (download + run `claude.ai/install.sh`)
3. Symlink config files: `CLAUDE.md`, `RTK.md`, `settings.json`, `keybindings.json`
4. Symlink each `config/hooks/*` file into `~/.claude/hooks/` (leave the dir as real — tool hooks write there independently)
5. Symlink `agents/` → `~/.claude/agents/`
6. Symlink each `skills/*.md` → `~/.claude/skills/`
7. Symlink `memory/` → `~/.claude/projects/<computed-path>/memory/`
8. Install plugins: parse `enabledPlugins` from `config/settings.json`, run `claude plugin install` for each
9. Run all executable `tools/install-*` scripts
10. Write `SOURCE_DIR` to `~/.claude/.claude-config-dir`
11. Write Unix timestamp to `~/.claude/.last-update`

**Memory path computation:**
```zsh
MEMORY_PROJECT_PATH=$(echo "$SOURCE_DIR" | sed 's|/|-|g')
MEMORY_DEST="$HOME/.claude/projects/$MEMORY_PROJECT_PATH/memory"
```

**Plugin list from settings.json** (node is already a declared dep):
```zsh
plugins=($(node -e "
  const s = require('$SOURCE_DIR/config/settings.json');
  console.log(Object.keys(s.enabledPlugins || {}).join('\n'));
"))
```

---

## `update` Script

1. `git -C "$SOURCE_DIR" pull`
2. Run `legacy/uninstall-*` scripts (idempotent deprecated-tool cleanup)
3. Clean dangling symlinks in `~/.claude/skills/`, `~/.claude/hooks/`, `~/.claude/agents/`:
   ```zsh
   for f in $DIR/*; do [[ -L $f && ! -e $f ]] && rm $f; done
   ```
4. Run `./install` (idempotent — picks up all additions)

---

## `uninstall` Script

No confirmation prompts — caller has chosen to run this.

1. Run `tools/uninstall-*` scripts
2. Run `legacy/uninstall-*` scripts
3. Remove all symlinks created by install (config files, skills, agents, hooks, memory dir)
4. Remove claude binary (native install):
   ```bash
   rm -f ~/.local/bin/claude
   rm -rf ~/.local/share/claude
   ```
5. Also handle npm install: if `npm list -g @anthropic-ai/claude-code` exits 0 → `npm uninstall -g @anthropic-ai/claude-code`
6. Remove config dirs:
   ```bash
   rm -rf ~/.claude
   rm -f ~/.claude.json
   ```

---

## Hooks

### `config/hooks/session-start-update-check` (SessionStart)

Runs at session open. Both checks are skipped if `~/.claude/.claude-config-dir` is missing.

**Auto-update:**
- Read timestamp from `~/.claude/.last-update`
- If missing or older than 12h → run `./update` from stored repo path
- Write fresh timestamp on success

**Dirty-repo reminder:**
- `git -C <repo-dir> status --porcelain`
- If non-empty → print: `"claude-config has uncommitted changes — commit and push before switching machines"`

---

## Security

### `config/git-hooks/pre-commit-secret-scan`

Installed to `.git/hooks/pre-commit` at install time (repo-local git hook, not a Claude hook).

Scans `config/settings.json` for secret-like values before each commit:
- Patterns in values: `sk-`, `ghp_`, `xoxb-`, `xoxp-`, `AKIA`
- Key names containing: `_KEY`, `_TOKEN`, `_SECRET`, `_PASSWORD`, `_API`

Blocks commit if found, lists suspicious keys.

### Policy (documented in CLAUDE.md)

Do not add secrets to `config/settings.json` env block. Use shell profile (`~/.zshrc` / `~/.zshenv`) instead. The settings.json file is committed to a (potentially public) git repo.

---

## Plugin Tracking

`config/settings.json` `enabledPlugins` is the authoritative plugin list. Claude Code writes to this file when you run `claude plugin install`, and since it is symlinked from the repo, changes land in the tracked file automatically. Commit and push to propagate to other machines.

`./install` derives the install list from `enabledPlugins` — no separate hardcoded array.

**Deprecation flow (plugins):**
1. Remove from `enabledPlugins` in `config/settings.json`
2. Add `legacy/uninstall-plugin-<name>` containing `claude plugin uninstall <name>`
3. Commit

---

## Tool Deprecation Flow

When removing an external tool:
1. Delete `tools/install-<name>`
2. Move `tools/uninstall-<name>` → `legacy/uninstall-<name>`
3. Commit

`./update` on any machine runs `legacy/uninstall-*`, removing the deprecated tool automatically.

---

## External Tools

Each needs an idempotent `install-*` and `uninstall-*` script. Actual uninstall commands require checking each tool's documentation during implementation:

| Tool | Install method | Notes |
|------|---------------|-------|
| rtk | `tools/install-rtk` (exists) | Add idempotency check; `rtk init -g` |
| ccstatusline | sirmalloc/ccstatusline | Research install/uninstall during impl |
| happy | slopus/happy | Research install/uninstall during impl |
| caveman | juliusbrussee/caveman | Verify: plugin or external binary? |
| codebase-memory-mcp | DeusData/codebase-memory-mcp | Research install/uninstall during impl |

---

## Bootstrapping Existing Machine

Before implementation: copy current `~/.claude/` config files into the repo:
- `~/.claude/CLAUDE.md` → `config/CLAUDE.md`
- `~/.claude/RTK.md` → `config/RTK.md`
- `~/.claude/settings.json` → `config/settings.json` (audit for secrets first)
- `~/.claude/keybindings.json` → `config/keybindings.json` (if exists)
- `~/.claude/hooks/` → `config/hooks/` (custom hooks only, not tool-managed)
- `~/.claude/agents/` → `agents/` (if any exist)
- `~/.claude/skills/` → `skills/` (custom skills)
- Existing memory at `~/.claude/projects/<path>/memory/` → `memory/`
