# Installer Reorganization & Repository Restructuring Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the Agent Forge repository into modular CLI components (`claude/`, `antigravity/`, `shared/`), establish `shared/tools/lib` for common helpers and path resolution, create declarative symlink manifests, update Makefile targets, and implement dead symlink cleanup.

**Architecture:** Move `00-tools/` to `shared/tools/`, remove empty root `agents/`, symlink root `CLAUDE.md` to `AGENTS.md`, implement `shared/tools/lib` with dynamic `ROOT_DIR` resolution, `apply_manifest`, and `clean_dead_symlinks`, create `claude/install`, `claude/uninstall`, `antigravity/install`, `antigravity/uninstall`, and update Makefile.

**Tech Stack:** zsh / bash / make / git

## Global Constraints

- Retain full functionality for both Claude Code CLI and Antigravity CLI.
- All scripts must source `shared/tools/lib` and compute their location relative to `ROOT_DIR`.
- Declarative `manifest.txt` files must be used for symlinks in `claude/config/` and `antigravity/config/`.
- Dead symlinks in `~/.claude` and `~/.gemini` must be cleaned during installation and uninstallation.

---

### Task 1: Restructure Shared Directory, Move Tools, and Create `shared/tools/lib`

**Files:**
- Move: `00-tools/*` -> `shared/tools/*`
- Create: `shared/tools/lib`
- Remove: `agents/` (root)
- Symlink: `CLAUDE.md` -> `AGENTS.md` (root)
- Modify: `.env.example`, `shared/tools/pre-commit-encrypt-wip`, `shared/tools/cycle-key`, `shared/tools/encrypt`, `shared/tools/decrypt`

- [ ] **Step 1: Move `00-tools/*` and `tools/*` into `shared/tools/` and remove root `agents/`**

```bash
mkdir -p shared/tools
cp -r 00-tools/* shared/tools/ 2>/dev/null || true
rm -rf 00-tools agents
ln -sf AGENTS.md CLAUDE.md
```

- [ ] **Step 2: Create `shared/tools/lib` with shared helpers and path resolution**

Write `shared/tools/lib`:

```bash
#!/usr/bin/env zsh
# shared/tools/lib — Shared library for Agent Forge installers and tools

# Dynamic path resolution relative to this script
LIB_DIR="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd || cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$LIB_DIR/../.." && pwd)"

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
GEMINI_DIR="${GEMINI_CONFIG_DIR:-$HOME/.gemini}"
ANTIGRAVITY_DIR="$GEMINI_DIR/antigravity-cli"

info()    { print -P "%F{blue}[info]%f:  $1" }
success() { print -P "%F{green}[ok]%f:    $1" }
warn()    { print -P "%F{yellow}[warn]%f:  $1" }
error()   { print -P "%F{red}[error]%f $1" && exit 1 }

symlink() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak"
    warn "Backed up $dest → $dest.bak"
  fi
  if ! ln -s "$src" "$dest"; then
    error "Failed to link $dest"
    return 1
  fi
  success "Linked $(basename "$dest")"
}

clean_dead_symlinks() {
  local target_dir=$1
  [[ -d "$target_dir" ]] || return 0
  for f in "$target_dir"/*(N); do
    if [[ -L "$f" && ! -e "$f" ]]; then
      rm "$f"
      info "Removed dangling symlink: $f"
    elif [[ -d "$f" && ! -L "$f" ]]; then
      clean_dead_symlinks "$f"
    fi
  done
}

apply_manifest() {
  local manifest_file=$1
  [[ -f "$manifest_file" ]] || error "Manifest file $manifest_file not found"
  while IFS=':' read -r rel_src raw_dest || [[ -n "$rel_src" ]]; do
    [[ -z "$rel_src" || "$rel_src" == "#"* ]] && continue
    local abs_src="$ROOT_DIR/$rel_src"
    local abs_dest
    abs_dest=$(eval echo "$raw_dest")
    if [[ -d "$abs_src" && "$rel_src" == *"/*" ]]; then
      local base_src="${abs_src%\/\*}"
      for f in "$base_src"/*(N/); do
        symlink "$f" "$abs_dest/$(basename "$f")"
      done
    elif [[ -f "$abs_src" ]]; then
      symlink "$abs_src" "$abs_dest"
    elif [[ -d "$abs_src" ]]; then
      symlink "$abs_src" "$abs_dest"
    fi
  done < "$manifest_file"
}

load_env() {
  local env_file="${1:-$ROOT_DIR/.env}"
  [[ -f "$env_file" ]] || error "missing $env_file — run shared/tools/create-key first"
  set -a
  source "$env_file"
  set +a
  [[ -n "$SKILLS_ENCRYPTION_KEY" ]] && export SKILLS_ENCRYPTION_KEY
}
```

- [ ] **Step 3: Update references to `00-tools/` across repo scripts**

Update `shared/tools/cycle-key`, `shared/tools/encrypt`, `shared/tools/pre-commit-encrypt-wip`, `.env.example`, `AGENTS.md` to reference `shared/tools/`.

- [ ] **Step 4: Verify `shared/tools/lib` and tool scripts**

Run: `zsh -c 'source shared/tools/lib && echo $ROOT_DIR'`
Expected: `/Users/jamesmacmillan/projects/personal/agent-forge`

- [ ] **Step 5: Commit Task 1**

```bash
git add shared/tools CLAUDE.md AGENTS.md .env.example
git rm -r 00-tools agents 2>/dev/null || true
git commit -m "refactor(structure): move tools to shared/tools, create shared/tools/lib, and symlink root CLAUDE.md"
```

---

### Task 2: Create Claude & Antigravity Manifests, Sub-installers, and Sub-uninstallers

**Files:**
- Create: `claude/config/manifest.txt`
- Create: `claude/install`
- Create: `claude/uninstall`
- Create: `antigravity/config/manifest.txt`
- Create: `antigravity/install`
- Create: `antigravity/uninstall`

- [ ] **Step 1: Create `claude/config/manifest.txt` and `claude/install` & `claude/uninstall`**

Write `claude/config/manifest.txt`:
```text
claude/config/CLAUDE.md:$CLAUDE_DIR/CLAUDE.md
claude/config/RTK.md:$CLAUDE_DIR/RTK.md
claude/config/settings.json:$CLAUDE_DIR/settings.json
claude/scripts/statusline.sh:$CLAUDE_DIR/statusline.sh
claude/hooks/*:$CLAUDE_DIR/hooks/
shared/memory:$CLAUDE_DIR/memory
shared/agents:$CLAUDE_DIR/agents
shared/skills/*:$CLAUDE_DIR/skills/
shared/skills-wip/*:$CLAUDE_DIR/skills/
```

Write `claude/install`:
```zsh
#!/usr/bin/env zsh
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd || cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/shared/tools/lib"

info "Installing Claude CLI configuration..."
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills"

clean_dead_symlinks "$CLAUDE_DIR"

apply_manifest "$SCRIPT_DIR/config/manifest.txt"

# Run shared and Claude-specific tool installers
for tool_script in "$ROOT_DIR/shared/tools/install-"*(N) "$SCRIPT_DIR/tools/install-"*(N); do
  [[ -x "$tool_script" ]] || continue
  info "Running $(basename "$tool_script")..."
  "$tool_script" || warn "$(basename "$tool_script") failed"
done

success "Claude CLI configuration installed."
```

Write `claude/uninstall`:
```zsh
#!/usr/bin/env zsh
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd || cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/shared/tools/lib"

info "Uninstalling Claude CLI configuration..."
clean_dead_symlinks "$CLAUDE_DIR"

for f in CLAUDE.md RTK.md settings.json .mcp.json keybindings.json statusline.sh memory agents; do
  [[ -L "$CLAUDE_DIR/$f" ]] && rm "$CLAUDE_DIR/$f" && info "Removed Claude $f"
done

if [[ -d "$CLAUDE_DIR/skills" && ! -L "$CLAUDE_DIR/skills" ]]; then
  for f in "$CLAUDE_DIR/skills/"*(N); do
    [[ -L "$f" ]] && rm "$f" && info "Removed Claude skill symlink $(basename "$f")"
  done
fi

if [[ -d "$CLAUDE_DIR/hooks" ]]; then
  for f in "$CLAUDE_DIR/hooks/"*(N); do
    [[ -L "$f" ]] && rm "$f" && info "Removed Claude hook symlink $(basename "$f")"
  done
fi

success "Claude CLI configuration uninstalled."
```

Make `claude/install` and `claude/uninstall` executable.

- [ ] **Step 2: Create `antigravity/config/manifest.txt` and `antigravity/install` & `antigravity/uninstall`**

Write `antigravity/config/manifest.txt`:
```text
antigravity/config/GEMINI.md:$GEMINI_DIR/GEMINI.md
antigravity/config/settings.json:$GEMINI_DIR/antigravity-cli/settings.json
antigravity/config/hooks.json:$GEMINI_DIR/config/hooks.json
antigravity/scripts/statusline.sh:$GEMINI_DIR/statusline.sh
antigravity/hooks/*:$GEMINI_DIR/config/hooks/
shared/memory:$GEMINI_DIR/config/memory
shared/agents:$GEMINI_DIR/config/agents
shared/skills/*:$GEMINI_DIR/config/skills/
shared/skills-wip/*:$GEMINI_DIR/config/skills/
```

Write `antigravity/install`:
```zsh
#!/usr/bin/env zsh
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd || cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/shared/tools/lib"

info "Installing Antigravity CLI configuration..."
mkdir -p "$GEMINI_DIR/config/hooks" "$GEMINI_DIR/config/skills" "$ANTIGRAVITY_DIR"

clean_dead_symlinks "$GEMINI_DIR"

apply_manifest "$SCRIPT_DIR/config/manifest.txt"

# Run shared and Antigravity-specific tool installers
for tool_script in "$ROOT_DIR/shared/tools/install-"*(N) "$SCRIPT_DIR/tools/install-"*(N); do
  [[ -x "$tool_script" ]] || continue
  info "Running $(basename "$tool_script")..."
  "$tool_script" || warn "$(basename "$tool_script") failed"
done

success "Antigravity CLI configuration installed."
```

Write `antigravity/uninstall`:
```zsh
#!/usr/bin/env zsh
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd || cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/shared/tools/lib"

info "Uninstalling Antigravity CLI configuration..."
clean_dead_symlinks "$GEMINI_DIR"

for f in GEMINI.md statusline.sh; do
  [[ -L "$GEMINI_DIR/$f" ]] && rm "$GEMINI_DIR/$f" && info "Removed Antigravity $f"
done

for f in settings.json; do
  [[ -L "$ANTIGRAVITY_DIR/$f" ]] && rm "$ANTIGRAVITY_DIR/$f" && info "Removed Antigravity $f"
done

for f in hooks.json memory agents; do
  [[ -L "$GEMINI_DIR/config/$f" ]] && rm "$GEMINI_DIR/config/$f" && info "Removed Antigravity config $f"
done

if [[ -d "$GEMINI_DIR/config/skills" && ! -L "$GEMINI_DIR/config/skills" ]]; then
  for f in "$GEMINI_DIR/config/skills/"*(N); do
    [[ -L "$f" ]] && rm "$f" && info "Removed Antigravity skill symlink $(basename "$f")"
  done
fi

success "Antigravity CLI configuration uninstalled."
```

Make `antigravity/install` and `antigravity/uninstall` executable.

- [ ] **Step 3: Test `claude/install` and `antigravity/install` independently**

Run: `./claude/install`
Expected: `[ok]   Claude CLI configuration installed.`

Run: `./antigravity/install`
Expected: `[ok]   Antigravity CLI configuration installed.`

- [ ] **Step 4: Commit Task 2**

```bash
git add claude/ antigravity/
git commit -m "feat(installers): add modular install/uninstall scripts and manifests for Claude and Antigravity"
```

---

### Task 3: Refactor Root Install, Uninstall, and Makefile

**Files:**
- Modify: `install`
- Modify: `uninstall`
- Modify: `Makefile`

- [ ] **Step 1: Update root `install` script to delegate to sub-installers**

Rewrite root `install`:
```zsh
#!/usr/bin/env zsh
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd || cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
source "$ROOT_DIR/shared/tools/lib"

info "Starting Agent Forge Master Installation..."

# Install git hook
hook_src="$ROOT_DIR/shared/tools/pre-commit-encrypt-wip"
if [[ -f "$hook_src" ]]; then
  chmod +x "$hook_src"
  if hooks_dir=$(git -C "$ROOT_DIR" rev-parse --git-path hooks 2>/dev/null); then
    [[ "$hooks_dir" == /* ]] || hooks_dir="$ROOT_DIR/$hooks_dir"
    mkdir -p "$hooks_dir"
    symlink "$hook_src" "$hooks_dir/pre-commit"
  fi
fi

# Run Claude installer
if [[ -x "$ROOT_DIR/claude/install" ]]; then
  "$ROOT_DIR/claude/install" || warn "Claude installer failed"
fi

# Run Antigravity installer
if [[ -x "$ROOT_DIR/antigravity/install" ]]; then
  "$ROOT_DIR/antigravity/install" || warn "Antigravity installer failed"
fi

# Setup zsh aliases
zshrc="$HOME/.zshrc"
if [[ -f "$zshrc" ]] && ! grep -q "AI_CONFIG_DIR" "$zshrc" &>/dev/null; then
  info "Setting up shell aliases in ~/.zshrc..."
  {
    echo ""
    echo "export AI_CONFIG_DIR=\"$ROOT_DIR\""
    echo '[[ -f "$AI_CONFIG_DIR/zsh/aliases.zsh" ]] && source "$AI_CONFIG_DIR/zsh/aliases.zsh"'
  } >> "$zshrc"
  success "Added zsh/aliases.zsh sourcing to ~/.zshrc"
fi

success "Agent Forge fully installed."
```

- [ ] **Step 2: Update root `uninstall` script to delegate to sub-uninstallers**

Rewrite root `uninstall`:
```zsh
#!/usr/bin/env zsh
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd || cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
source "$ROOT_DIR/shared/tools/lib"

info "Starting Agent Forge Master Uninstallation..."

if [[ -x "$ROOT_DIR/claude/uninstall" ]]; then
  "$ROOT_DIR/claude/uninstall" || warn "Claude uninstaller failed"
fi

if [[ -x "$ROOT_DIR/antigravity/uninstall" ]]; then
  "$ROOT_DIR/antigravity/uninstall" || warn "Antigravity uninstaller failed"
fi

# Remove zsh aliases
zshrc="$HOME/.zshrc"
if [[ -f "$zshrc" ]] && grep -q "AI_CONFIG_DIR" "$zshrc" &>/dev/null; then
  info "Removing AI_CONFIG_DIR from ~/.zshrc..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/AI_CONFIG_DIR/d' "$zshrc" 2>/dev/null
  else
    sed -i '/AI_CONFIG_DIR/d' "$zshrc" 2>/dev/null
  fi
  success "Removed shell aliases block from ~/.zshrc"
fi

success "Agent Forge uninstalled."
```

- [ ] **Step 3: Update `Makefile` targets**

Rewrite `Makefile`:
```makefile
SHELL := zsh
.ONESHELL:
.SILENT:

install:
	./install
.PHONY: install

claude:
	./claude/install
.PHONY: claude

antigravity:
	./antigravity/install
.PHONY: antigravity

uninstall:
	./uninstall
.PHONY: uninstall

uninstall-claude:
	./claude/uninstall
.PHONY: uninstall-claude

uninstall-antigravity:
	./antigravity/uninstall
.PHONY: uninstall-antigravity
```

- [ ] **Step 4: Execute Makefile targets and verify full setup**

Run: `make install`
Expected: Successfully installs Claude and Antigravity configurations.

Run: `make claude`
Expected: Successfully runs Claude sub-installer.

Run: `make antigravity`
Expected: Successfully runs Antigravity sub-installer.

- [ ] **Step 5: Commit Task 3**

```bash
git add install uninstall Makefile
git commit -m "refactor(installers): delegate master install/uninstall to sub-installers and update Makefile targets"
```
