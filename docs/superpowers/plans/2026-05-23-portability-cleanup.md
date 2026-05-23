# Portability & Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix cross-machine install portability so `git diff` is empty after a fresh install on any supported platform (Ubuntu 22/24/26, Arch, macOS), unify script output format, and add a gitignored env.local mechanism for per-machine secrets.

**Architecture:** Six independent tasks, each with a commit. Shared helpers go to `tools/lib.sh` sourced by all tool scripts. Machine-specific content is either normalized at install time (caveman paths) or dropped from the repo entirely (.mcp.json). Secrets live in a gitignored `config/env.local` that install sources into `~/.zshenv`.

**Tech Stack:** zsh (>= 5.0), jq (optional fallback to perl), curl, standard POSIX sh for bootstrap shim.

---

### Task 1: Commit existing working-tree improvements

These are already-correct changes sitting in the working tree that should be committed before new work begins.

**Files:**
- Modify: `config/hooks/cbm-code-discovery-gate` (simplified version already in working tree)
- Modify: `config/settings.json` (key ordering already in working tree)

- [ ] **Step 1: Verify working tree state**

```bash
git diff config/hooks/cbm-code-discovery-gate config/settings.json
```

Expected: cbm-code-discovery-gate is the simplified 12-line version; settings.json has `skipDangerousModePermissionPrompt` before `theme`.

- [ ] **Step 2: Stage and commit**

```bash
git add config/hooks/cbm-code-discovery-gate config/settings.json
git commit -m "simplify cbm-code-discovery-gate, fix settings.json key order"
```

---

### Task 2: Create shared helpers lib

Extract the 4 color helpers from install into a sourced lib so every tool script uses identical output formatting.

**Files:**
- Create: `tools/lib.sh`

- [ ] **Step 1: Create `tools/lib.sh`**

```bash
cat > /path/to/repo/tools/lib.sh << 'EOF'
#!/usr/bin/env zsh
info()    { print -P "%F{blue}[info]%f  $1" }
success() { print -P "%F{green}[ok]%f    $1" }
warn()    { print -P "%F{yellow}[warn]%f  $1" }
error()   { print -P "%F{red}[error]%f $1"; exit 1 }
EOF
chmod +x tools/lib.sh
```

Use the Write tool to create `tools/lib.sh` with this exact content:
```zsh
#!/usr/bin/env zsh
info()    { print -P "%F{blue}[info]%f  $1" }
success() { print -P "%F{green}[ok]%f    $1" }
warn()    { print -P "%F{yellow}[warn]%f  $1" }
error()   { print -P "%F{red}[error]%f $1"; exit 1 }
```

- [ ] **Step 2: Update `tools/install-caveman` to source lib**

Replace the existing `echo "[ok]"` / `echo "[info]"` / `echo "[error]"` calls:

```zsh
#!/usr/bin/env zsh
source "${0:a:h}/lib.sh"

info "Installing caveman..."
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh \
  | bash || error "Caveman install failed"

success "caveman installed"
info "Note: caveman installer updates settings.json hook paths for this machine."
info "Commit settings.json changes only if the plugin list changed, not hook paths."
```

- [ ] **Step 3: Update `tools/install-codebase-memory-mcp` to source lib**

```zsh
#!/usr/bin/env zsh
source "${0:a:h}/lib.sh"

if command -v codebase-memory-mcp &> /dev/null; then
  success "codebase-memory-mcp already installed"
else
  info "Installing codebase-memory-mcp..."
  curl -fsSL \
    https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh \
    | bash || error "codebase-memory-mcp install failed"
fi

info "Running codebase-memory-mcp install (configure auto-index)..."
codebase-memory-mcp install \
  || warn "codebase-memory-mcp post-install step failed — run 'codebase-memory-mcp install' manually to configure auto-indexing"

success "codebase-memory-mcp installed"
```

- [ ] **Step 4: Update `tools/install-rtk` to source lib**

```zsh
#!/usr/bin/env zsh
source "${0:a:h}/lib.sh"

if command -v rtk &> /dev/null; then
  success "rtk already installed"
  exit 0
fi

info "Installing rtk..."
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh \
  -o /tmp/rtk-install.sh || error "Failed to download rtk installer"

chmod +x /tmp/rtk-install.sh
/tmp/rtk-install.sh || error "rtk installer failed"
rm -f /tmp/rtk-install.sh

rtk init -g || error "rtk init -g failed"
success "rtk installed"
```

- [ ] **Step 5: Update `tools/install-happy` to source lib**

```zsh
#!/usr/bin/env zsh
source "${0:a:h}/lib.sh"

if command -v happy &> /dev/null; then
  success "happy already installed"
  exit 0
fi

info "Installing happy..."
npm install -g happy || error "Failed to install happy"
success "happy installed"
```

- [ ] **Step 6: Update `tools/install-ccstatusline` to source lib**

```zsh
#!/usr/bin/env zsh
source "${0:a:h}/lib.sh"

SCRIPT_DIR=${0:a:h}
TEMPLATE="$SCRIPT_DIR/../config/ccstatusline-settings.json"
DEST="$HOME/.config/ccstatusline/settings.json"

[[ -f "$TEMPLATE" ]] || error "template not found: $TEMPLATE"

mkdir -p "$(dirname "$DEST")"

if [[ -f "$DEST" ]] && [[ "$DEST" -nt "$TEMPLATE" ]]; then
  success "ccstatusline config already up to date"
  exit 0
fi

sed "s|__HOME__|$HOME|g" "$TEMPLATE" > "$DEST" || error "failed to write $DEST"
success "ccstatusline config written to $DEST"
```

- [ ] **Step 7: Update `tools/install-claude-monitor` to source lib**

```zsh
#!/usr/bin/env zsh
source "${0:a:h}/lib.sh"

if ! command -v uv &> /dev/null; then
  error "uv not found — install it first: https://docs.astral.sh/uv/getting-started/installation/"
fi

if uv tool list 2>/dev/null | grep -q "^claude-monitor"; then
  success "claude-monitor already installed"
  exit 0
fi

info "Installing claude-monitor..."
uv tool install claude-monitor || error "claude-monitor install failed"
success "claude-monitor installed — run: claude-monitor"
```

- [ ] **Step 8: Update `install` script to source lib**

In the `install` script, remove the 4 existing color helper function definitions (lines 6–9) and replace with:

```zsh
source "$SOURCE_DIR/tools/lib.sh"
```

This line should go immediately after `SOURCE_DIR=${0:a:h}`.

- [ ] **Step 9: Verify install still runs**

```bash
./install 2>&1 | head -20
```

Expected: colored `[ok]` / `[info]` lines, no errors.

- [ ] **Step 10: Commit**

```bash
git add tools/lib.sh tools/install-caveman tools/install-codebase-memory-mcp tools/install-rtk tools/install-happy tools/install-ccstatusline tools/install-claude-monitor install
git commit -m "extract shared color helpers to tools/lib.sh, unify script output"
```

---

### Task 3: Fix install script — zsh bootstrap and curl

**Files:**
- Modify: `install`

- [ ] **Step 1: Replace the shebang with a sh/zsh bootstrap shim**

Replace the first line `#!/usr/bin/env zsh` with this block:

```sh
#!/bin/sh
# Re-exec with zsh (required). Install zsh first if missing:
#   Ubuntu/Debian: sudo apt-get install zsh
#   Arch:          sudo pacman -S zsh
#   macOS:         brew install zsh
if [ -z "$ZSH_VERSION" ]; then
  if ! command -v zsh >/dev/null 2>&1; then
    echo "[error] zsh required. Install it first:"
    echo "  Ubuntu/Debian: sudo apt-get install zsh"
    echo "  Arch:          sudo pacman -S zsh"
    echo "  macOS:         brew install zsh"
    exit 1
  fi
  exec zsh "$0" "$@"
fi
```

Everything from `SOURCE_DIR=...` onward stays unchanged.

- [ ] **Step 2: Remove `http` from deps, replace its use with curl**

In `check_deps()`, change:
```zsh
local deps=(node npx npm http)
```
to:
```zsh
local deps=(node npx npm curl)
```

In `install_claude()`, replace:
```zsh
http --download --output /tmp/claude-installer.sh https://claude.ai/install.sh \
  || error "Failed to download claude installer"
```
with:
```zsh
curl -fsSL -o /tmp/claude-installer.sh https://claude.ai/install.sh \
  || error "Failed to download claude installer"
```

- [ ] **Step 3: Verify the shim works**

```bash
sh ./install 2>&1 | head -5
```

Expected: same colored output as before (zsh gets re-exec'd), no "zsh not found" error.

- [ ] **Step 4: Commit**

```bash
git add install
git commit -m "add zsh bootstrap shim to install, replace http with curl"
```

---

### Task 4: Normalize caveman hook paths after install

The caveman installer writes absolute paths like `node "/home/james/.claude/hooks/caveman-activate.js"` into `settings.json`. This creates a dirty diff on every new machine. After caveman installs, normalize those paths to the portable `node ~/.claude/hooks/caveman-activate.js` form.

**Files:**
- Modify: `tools/install-caveman`
- Modify: `config/settings.json` (the normalize step rewrites it)

- [ ] **Step 1: Add normalize step to `tools/install-caveman`**

After the curl install line, add a normalization function and call:

```zsh
#!/usr/bin/env zsh
source "${0:a:h}/lib.sh"

info "Installing caveman..."
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh \
  | bash || error "Caveman install failed"

# Normalize absolute hook paths written by caveman installer to portable ~/... form.
# caveman writes: node "/abs/path/.claude/hooks/foo.js"
# we want:        node ~/.claude/hooks/foo.js
local settings="$HOME/.claude/settings.json"
if [[ -f "$settings" ]]; then
  perl -i -pe 's|node ".*?\.claude/hooks/([^"]+)"|node ~/.claude/hooks/$1|g' "$settings"
  success "caveman hook paths normalized"
fi

success "caveman installed"
info "Commit settings.json changes only if the plugin list changed, not hook paths."
```

- [ ] **Step 2: Run the normalization on the current settings.json**

The current `settings.json` has Linux absolute paths. Run the normalize step manually:

```bash
perl -i -pe 's|node ".*?\.claude/hooks/([^"]+)"|node ~/.claude/hooks/$1|g' ~/.claude/settings.json
```

- [ ] **Step 3: Verify settings.json has portable paths**

```bash
grep "caveman" config/settings.json
```

Expected output (no absolute paths):
```
"command": "node ~/.claude/hooks/caveman-activate.js",
...
"command": "node ~/.claude/hooks/caveman-mode-tracker.js",
```

- [ ] **Step 4: Verify caveman hooks still fire**

Start a new Claude Code session, check that caveman mode activates (session should show CAVEMAN MODE ACTIVE in the system reminder).

- [ ] **Step 5: Commit**

```bash
git add tools/install-caveman config/settings.json
git commit -m "normalize caveman hook paths to portable ~/... form after install"
```

---

### Task 5: Drop .mcp.json from repo — let tool manage it

`config/.mcp.json` contains the absolute path to `codebase-memory-mcp`. This changes per machine and creates a dirty diff after every install. The `codebase-memory-mcp install` subcommand already writes to `~/.claude/.mcp.json` directly, so the repo copy is redundant.

**Files:**
- Modify: `install` (remove .mcp.json symlink call)
- Modify: `.gitignore` (add config/.mcp.json)
- Remove from git tracking: `config/.mcp.json`

- [ ] **Step 1: Remove .mcp.json symlink from `install` and add transition cleanup**

In the `link_config()` function, remove this line:
```zsh
symlink "$SOURCE_DIR/config/.mcp.json"     "$claude_dir/.mcp.json"
```

And add this cleanup block just after the remaining symlink calls (to handle the transition on machines that already have the symlink):

```zsh
# Remove legacy .mcp.json symlink if it still points into the repo
local mcp_link="$claude_dir/.mcp.json"
if [[ -L "$mcp_link" ]] && [[ "$(readlink "$mcp_link")" == "$SOURCE_DIR/config/.mcp.json" ]]; then
  rm "$mcp_link"
  warn "Removed legacy .mcp.json symlink — codebase-memory-mcp manages this now"
fi
```

- [ ] **Step 2: Add config/.mcp.json to .gitignore**

At the bottom of `.gitignore`, add:
```
# Machine-specific — managed by codebase-memory-mcp install
config/.mcp.json
```

- [ ] **Step 3: Untrack config/.mcp.json from git**

```bash
git rm --cached config/.mcp.json
```

- [ ] **Step 4: Verify `~/.claude/.mcp.json` exists and has the correct path**

```bash
cat ~/.claude/.mcp.json
```

Expected: `codebase-memory-mcp` entry with the correct local binary path. If missing, run:

```bash
codebase-memory-mcp install
```

- [ ] **Step 5: Verify MCP server still loads**

Start Claude Code. Check that `mcp__codebase-memory-mcp__*` tools appear in the available tools list (or that `index_repository` works).

- [ ] **Step 6: Commit**

```bash
git add install .gitignore
git commit -m "drop config/.mcp.json from repo, let codebase-memory-mcp manage it"
```

---

### Task 6: Secrets — gitignored env.local with shell sourcing

Add a gitignored `config/env.local` that install idempotently sources into `~/.zshenv`. This lets per-machine secrets (GitHub PAT, etc.) live in the repo directory without being committed.

**Files:**
- Create: `config/env.local.example`
- Modify: `.gitignore` (add config/env.local)
- Modify: `install` (add setup_env_local function)
- Modify: `config/CLAUDE.md` (document the pattern)

- [ ] **Step 1: Create `config/env.local.example`**

```bash
# config/env.local.example
# Copy to config/env.local (gitignored) and fill in per-machine secrets.
# install will source this file into ~/.zshenv so Claude Code inherits the vars.

# GitHub Personal Access Token — needed by the github plugin
# GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...

# Add other machine-specific env vars below:
```

- [ ] **Step 2: Add config/env.local to .gitignore**

Append to `.gitignore`:
```
# Per-machine secrets — never commit
config/env.local
```

- [ ] **Step 3: Add `setup_env_local` to `install` script**

Add this function to `install`, just before the `# ── main ──` section:

```zsh
# ── source env.local from ~/.zshenv (idempotent) ───────────────────────────
function setup_env_local() {
  local env_file="$SOURCE_DIR/config/env.local"
  local marker="# claude-config env.local"
  local zshenv="$HOME/.zshenv"

  # If no env.local yet, create from example and skip sourcing
  if [[ ! -f "$env_file" ]]; then
    [[ -f "$SOURCE_DIR/config/env.local.example" ]] && \
      cp "$SOURCE_DIR/config/env.local.example" "$env_file"
    info "Created config/env.local — add secrets there (gitignored)"
    return
  fi

  # Idempotently add source line to ~/.zshenv
  if ! grep -qF "$marker" "$zshenv" 2>/dev/null; then
    printf '\n%s\n[[ -f "%s" ]] && source "%s"\n' \
      "$marker" "$env_file" "$env_file" >> "$zshenv"
    success "env.local wired into ~/.zshenv"
  else
    success "env.local already wired"
  fi
}
```

Call it in the main section just before `install_tools`:
```zsh
setup_env_local
install_tools
```

- [ ] **Step 4: Update `config/CLAUDE.md` security section**

In the **Security** section of `config/CLAUDE.md`, replace:
```markdown
**Do not add secrets to `config/settings.json` env block** — this file is committed to git. Use `~/.zshrc` or `~/.zshenv` for environment secrets instead.
```
with:
```markdown
**Do not add secrets to `config/settings.json` env block** — this file is committed to git.

For per-machine secrets (API tokens, PATs): add them to `config/env.local` (gitignored, created by `./install`). The install script sources it into `~/.zshenv` so Claude Code and all tools inherit the vars automatically. A template is at `config/env.local.example`.
```

- [ ] **Step 5: Run install and verify env.local is created**

```bash
./install 2>&1 | grep -E "env.local|ok|info"
```

Expected: line like `[ok] env.local already wired` or `[info] Created config/env.local`.

```bash
ls -la config/env.local
```

Expected: file exists, not symlink.

```bash
git status config/env.local
```

Expected: file not tracked (gitignored).

- [ ] **Step 6: Test secret flow**

Add a test var to `config/env.local`:
```bash
echo "TEST_SECRET=hello_from_env_local" >> config/env.local
```

Open a new terminal and verify:
```bash
echo $TEST_SECRET
```

Expected: `hello_from_env_local`

Remove the test line from env.local afterward.

- [ ] **Step 7: Commit**

```bash
git add config/env.local.example .gitignore install config/CLAUDE.md
git commit -m "add gitignored env.local for per-machine secrets, wire into ~/.zshenv"
```

---

### Verification: Clean install produces no git diff

After all tasks are complete, verify the goal: a fresh `./install` on this machine produces no git diff.

- [ ] **Step 1: Run install**

```bash
./install
```

- [ ] **Step 2: Check git status**

```bash
git status
```

Expected: `nothing to commit, working tree clean` (or only `config/env.local` which is gitignored).

```bash
git diff
```

Expected: empty output.

- [ ] **Step 3: Check all tools work**

```bash
rtk --version && echo "[ok] rtk" || echo "[error] rtk"
command -v codebase-memory-mcp && echo "[ok] codebase-memory-mcp" || echo "[error] codebase-memory-mcp"
command -v claude && echo "[ok] claude" || echo "[error] claude"
command -v happy && echo "[ok] happy" || echo "[error] happy"
command -v claude-monitor && echo "[ok] claude-monitor" || echo "[error] claude-monitor"
```

Expected: all `[ok]`.
