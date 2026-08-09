---
title: Installer Reorganization & Repository Restructuring Design
date: 2026-08-09
---

# Installer Reorganization & Repository Restructuring Design

## Overview

Restructure the **Agent Forge** repository to establish clean, modular per-CLI installation scripts, standardized directory layouts across `claude/`, `antigravity/`, and `shared/`, a unified `Makefile`, declarative symlink manifests, and a shared helper library at `shared/tools/lib`.

---

## Directory & File Structure

```
agent-forge/
├── Makefile                          # Unified targets (install, claude, antigravity, uninstall, etc.)
├── install                           # Master installer (delegates to sub-installers)
├── uninstall                         # Master uninstaller (delegates to sub-uninstallers)
├── AGENTS.md                         # Core reference
├── CLAUDE.md                         # Claude instructions
├── README.md                         # Documentation
├── antigravity/                      # Antigravity CLI module
│   ├── config/                       # GEMINI.md, settings.json, hooks.json, manifest.txt
│   ├── hooks/                        # adhd-mode-inject-skill, session-stop-memory-reminder
│   ├── scripts/                      # statusline.sh
│   ├── tools/                        # Antigravity-specific tool installers (install-*)
│   ├── install                       # Executable sub-installer for Antigravity
│   └── uninstall                     # Executable sub-uninstaller for Antigravity
├── claude/                           # Claude Code CLI module
│   ├── config/                       # CLAUDE.md, RTK.md, settings.json, keybindings.json, manifest.txt
│   ├── hooks/                        # adhd-mode-*, session-stop-memory-reminder
│   ├── scripts/                      # statusline.sh
│   ├── tools/                        # Claude-specific tool installers (install-*)
│   ├── install                       # Executable sub-installer for Claude
│   └── uninstall                     # Executable sub-uninstaller for Claude
├── shared/                           # Shared assets and tools
│   ├── agents/                       # Shared subagent definitions
│   ├── memory/                       # Shared memory
│   ├── scripts/                      # CLI runtime scripts
│   ├── skills/                       # Shared skills
│   ├── skills-wip/                   # Shared WIP skills
│   ├── system-prompt/                # Workflow definitions
│   └── tools/                        # Repo tools & lib (create-key, decrypt, encrypt, install-*, lib)
│       ├── install-caveman           # Shared tool installer
│       ├── install-claude-monitor     # Shared tool installer
│       ├── install-rtk               # Shared tool installer
│       ├── install-superpowers       # Shared tool installer
│       └── lib                       # Shared library sourced by all scripts
└── zsh/
    └── aliases.zsh                   # Unified shell aliases
```

### Removals & Moves
- **Remove:** Root-level empty `agents/` folder.
- **Move:** `00-tools/*` -> `shared/tools/`.
- **Move:** `tools/*` -> `shared/tools/` (or CLI-specific `claude/tools/` / `antigravity/tools/`).
- **Update References:** Update all `.env.example`, `pre-commit`, `encrypt`, `decrypt`, `cycle-key`, and documentation files to point to `shared/tools/`.

---

## Core Components & Functionality

### 1. Makefile Targets
- `install` (default): Runs `./install`.
- `claude`: Runs `./claude/install`.
- `antigravity`: Runs `./antigravity/install`.
- `uninstall`: Runs `./uninstall`.
- `uninstall-claude`: Runs `./claude/uninstall`.
- `uninstall-antigravity`: Runs `./antigravity/uninstall`.

### 2. Shared Library (`shared/tools/lib`)
Every installer, uninstaller, and repo script sources `shared/tools/lib`.
- **Path Resolution:**
  ```bash
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  # Compute ROOT_DIR dynamically based on distance to repo root
  ```
- **Shared Variables:** `ROOT_DIR`, `CLAUDE_DIR`, `GEMINI_DIR`, `ANTIGRAVITY_DIR`.
- **Logging Helpers:** `info`, `success`, `warn`, `error`.
- **Symlink Helpers:** `symlink_file`, `symlink_dir`.
- **Dead Symlink Cleaner (`clean_dead_symlinks`):** Traverses target config directories (`~/.claude`, `~/.gemini/config`, `~/.gemini/antigravity-cli`) and removes broken/dangling symlinks.
- **Manifest Processor (`apply_manifest`):** Reads a declarative `manifest.txt` file and creates symlinks for each `source:target` entry.

### 3. Declarative Symlink Manifests
`claude/config/manifest.txt` and `antigravity/config/manifest.txt` store line-by-line `source:target` mapping rules.
Lines starting with `#` or blank lines are ignored.

- **Example `claude/config/manifest.txt`:**
  ```text
  claude/config/CLAUDE.md:$CLAUDE_DIR/CLAUDE.md
  claude/config/RTK.md:$CLAUDE_DIR/RTK.md
  claude/config/settings.json:$CLAUDE_DIR/settings.json
  claude/scripts/statusline.sh:$CLAUDE_DIR/statusline.sh
  shared/memory:$CLAUDE_DIR/memory
  shared/agents:$CLAUDE_DIR/agents
  ```

- **Example `antigravity/config/manifest.txt`:**
  ```text
  antigravity/config/GEMINI.md:$GEMINI_DIR/GEMINI.md
  antigravity/config/settings.json:$GEMINI_DIR/antigravity-cli/settings.json
  antigravity/config/hooks.json:$GEMINI_DIR/config/hooks.json
  antigravity/scripts/statusline.sh:$GEMINI_DIR/statusline.sh
  shared/memory:$GEMINI_DIR/config/memory
  shared/agents:$GEMINI_DIR/config/agents
  ```

### 4. Tool & Plugin Installers
- **Tool Installer Loop:** CLI installers execute all executable scripts in `shared/tools/install-*` AND `<cli>/tools/install-*`.
- **Antigravity Plugins:** `install-superpowers` installs plugins into `~/.gemini/config/plugins/<plugin>` using `agy plugin install <url>` or direct config linking, ensuring persistent plugin loading.

---

## Verification & Testing Plan
1. **Symlink & Clean Test:** Verify `clean_dead_symlinks` removes dead links.
2. **Individual CLI Installs:** Run `make claude` and `make antigravity` separately; verify symlinks, skills, hooks, and statuslines.
3. **Master Install:** Run `make install`; verify full sync across both CLIs.
4. **Uninstall Tests:** Run `make uninstall-claude`, `make uninstall-antigravity`, and `make uninstall`; verify clean restoration and cleanup.
