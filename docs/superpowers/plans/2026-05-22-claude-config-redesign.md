# Claude Config Repo Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform claude-config into a one-stop bootstrap: `./install` fully configures Claude Code on a new machine; `./update` syncs after git pull; `./uninstall` cleanly removes everything.

**Architecture:** Flat scripts + symlink-based config management. `config/` holds tracked files symlinked to `~/.claude/`; `tools/` holds per-tool install/uninstall scripts; `legacy/` holds uninstall scripts for deprecated tools. `install` is idempotent and re-runnable. Plugin list is derived from `config/settings.json#enabledPlugins` — no separate array.

**Tech Stack:** zsh scripts, node (JSON parsing), git hooks (bash)

---

## File Map

**Created:**
- `config/CLAUDE.md` — symlinked to `~/.claude/CLAUDE.md`
- `config/RTK.md` — symlinked to `~/.claude/RTK.md`
- `config/settings.json` — symlinked to `~/.claude/settings.json` (normalised: no abs node paths)
- `config/.mcp.json` — symlinked to `~/.claude/.mcp.json`
- `config/hooks/post-agent-reminder` — symlinked into `~/.claude/hooks/`
- `config/hooks/session-start-update-check` — symlinked into `~/.claude/hooks/`
- `config/git-hooks/pre-commit-secret-scan` — installed to `.git/hooks/pre-commit`
- `agents/.gitkeep` — tracked empty dir, symlinked to `~/.claude/agents/`
- `skills/writing-quality.md` — symlinked into `~/.claude/skills/`
- `memory/.gitkeep` — tracked empty dir, symlinked to `~/.claude/projects/<path>/memory/`
- `legacy/.gitkeep` — tracked empty dir for future deprecated tool scripts
- `tools/install-rtk` — rewritten from existing
- `tools/uninstall-rtk`
- `tools/install-happy`
- `tools/uninstall-happy`
- `tools/install-caveman`
- `tools/uninstall-caveman`
- `tools/install-codebase-memory-mcp`
- `tools/uninstall-codebase-memory-mcp`

**Rewritten:**
- `install` — full rewrite
- `update` — new script
- `uninstall` — new script
- `.gitignore` — add `.last-update`, `.claude-config-dir`
- `CLAUDE.md` — update to reflect new structure
- `readme.md` — update

**Deleted:**
- `tools/install-rtk` (the old one, replaced)

**Not tracked (tool-managed):**
- `~/.claude/hooks/caveman-*.js` — managed by caveman installer
- `~/.claude/hooks/cbm-*` — managed by codebase-memory-mcp
- `~/.claude/skills/codebase-memory/` — managed by codebase-memory-mcp
- ccstatusline has no install script — driven entirely by `statusLine` block in `settings.json`

---

## Task 1: Bootstrap Config Files

Copy current `~/.claude/` files into repo structure. Normalise machine-specific absolute paths in `settings.json`.

**Files:** `config/CLAUDE.md`, `config/RTK.md`, `config/settings.json`, `config/.mcp.json`, `config/hooks/post-agent-reminder`, `skills/writing-quality.md`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /home/james/projects/personal/claude-config/config/hooks
mkdir -p /home/james/projects/personal/claude-config/config/git-hooks
mkdir -p /home/james/projects/personal/claude-config/agents
mkdir -p /home/james/projects/personal/claude-config/skills
mkdir -p /home/james/projects/personal/claude-config/memory
mkdir -p /home/james/projects/personal/claude-config/legacy
touch /home/james/projects/personal/claude-config/agents/.gitkeep
touch /home/james/projects/personal/claude-config/memory/.gitkeep
touch /home/james/projects/personal/claude-config/legacy/.gitkeep
```

- [ ] **Step 2: Copy config files**

```bash
cp ~/.claude/CLAUDE.md /home/james/projects/personal/claude-config/config/CLAUDE.md
cp ~/.claude/RTK.md /home/james/projects/personal/claude-config/config/RTK.md
cp ~/.claude/.mcp.json /home/james/projects/personal/claude-config/config/.mcp.json
```

- [ ] **Step 3: Copy and normalise settings.json**

Copy settings.json then replace the absolute asdf node path with just `node` so it's portable (caveman installer will re-add the correct path on each machine):

```bash
cp ~/.claude/settings.json /home/james/projects/personal/claude-config/config/settings.json
# Normalise: replace abs node path in caveman hook commands
sed -i 's|"/home/[^"]*/.asdf/installs/nodejs/[^"]*/bin/node" ||g' \
  /home/james/projects/personal/claude-config/config/settings.json
```

Verify the result — the caveman hook commands should now start with just `node`:
```bash
grep -A1 "caveman-activate\|caveman-mode-tracker" \
  /home/james/projects/personal/claude-config/config/settings.json
```
Expected: `"command": "node \"/home/james/.claude/hooks/caveman-activate.js\""` (no asdf path prefix)

- [ ] **Step 4: Copy custom hooks**

```bash
cp ~/.claude/hooks/post-agent-reminder \
  /home/james/projects/personal/claude-config/config/hooks/post-agent-reminder
chmod +x /home/james/projects/personal/claude-config/config/hooks/post-agent-reminder
```

- [ ] **Step 5: Copy custom skills**

```bash
cp ~/.claude/skills/writing-quality.md \
  /home/james/projects/personal/claude-config/skills/writing-quality.md
```

- [ ] **Step 6: Audit settings.json for secrets**

```bash
node -e "
  const s = require('./config/settings.json');
  const env = s.env || {};
  const keys = Object.keys(env);
  if (keys.length > 0) console.log('env block keys:', keys);
  else console.log('No env block — clean');
" --input-type=module 2>/dev/null || \
node -e "const s=require('./config/settings.json'); const env=s.env||{}; console.log('env keys:', Object.keys(env));"
```

Expected: `env keys: []` or `No env block — clean`. If secrets found, remove them from settings.json before proceeding.

- [ ] **Step 7: Commit**

```bash
cd /home/james/projects/personal/claude-config
git add config/ agents/ skills/ memory/ legacy/
git commit -m "bootstrap config files from ~/.claude/"
```

---

## Task 2: Update .gitignore

- [ ] **Step 1: Add runtime state files to .gitignore**

Append to `.gitignore`:

```
# Claude config runtime state (machine-specific, not tracked)
.last-update
.claude-config-dir
```

- [ ] **Step 2: Commit**

```bash
git add .gitignore
git commit -m "ignore runtime state files"
```

---

## Task 3: Rewrite `install` Script

Rewrite the existing `install` script. Fixes: `local` outside function (zsh bug), no colour output, no idempotent symlink cleanup. Adds: config symlinking, agents, skills, memory, hooks, plugin bootstrap from settings.json, metadata write.

**File:** `install`

- [ ] **Step 1: Write the install script**

```zsh
#!/usr/bin/env zsh

SOURCE_DIR=${0:a:h}

# ── colour helpers ─────────────────────────────────────────────────────────
info()    { print -P "%F{blue}[info]%f  $1" }
success() { print -P "%F{green}[ok]%f    $1" }
warn()    { print -P "%F{yellow}[warn]%f  $1" }
error()   { print -P "%F{red}[error]%f $1"; exit 1 }

# ── symlink helper: idempotent, backs up real files ─────────────────────────
function symlink() {
  local src=$1 dest=$2
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak"
    warn "Backed up $dest → $dest.bak"
  fi
  ln -s "$src" "$dest"
  success "Linked $(basename $dest)"
}

# ── dependency check ────────────────────────────────────────────────────────
function check_deps() {
  local deps=(node npx npm http)
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      error "$dep not found — install it first"
    fi
  done
  success "Dependencies OK"
}

# ── install claude CLI if missing ───────────────────────────────────────────
function install_claude() {
  if command -v claude &> /dev/null; then
    success "claude already installed"
    return
  fi
  info "Installing claude CLI..."
  http --download --output /tmp/claude-installer.sh https://claude.ai/install.sh \
    || error "Failed to download claude installer"
  chmod +x /tmp/claude-installer.sh
  /tmp/claude-installer.sh || error "claude installer failed"
  rm -f /tmp/claude-installer.sh
}

# ── symlink config files ────────────────────────────────────────────────────
function link_config() {
  local claude_dir="$HOME/.claude"

  symlink "$SOURCE_DIR/config/CLAUDE.md"     "$claude_dir/CLAUDE.md"
  symlink "$SOURCE_DIR/config/RTK.md"        "$claude_dir/RTK.md"
  symlink "$SOURCE_DIR/config/settings.json" "$claude_dir/settings.json"
  symlink "$SOURCE_DIR/config/.mcp.json"     "$claude_dir/.mcp.json"

  [[ -f "$SOURCE_DIR/config/keybindings.json" ]] && \
    symlink "$SOURCE_DIR/config/keybindings.json" "$claude_dir/keybindings.json"
}

# ── symlink individual hooks into ~/.claude/hooks/ ──────────────────────────
function link_hooks() {
  local hooks_dir="$HOME/.claude/hooks"
  mkdir -p "$hooks_dir"

  for hook_file in "$SOURCE_DIR/config/hooks/"*(N); do
    [[ -f "$hook_file" ]] || continue
    local name=$(basename "$hook_file")
    symlink "$hook_file" "$hooks_dir/$name"
    chmod +x "$hook_file"
  done
}

# ── symlink agents/ directory ───────────────────────────────────────────────
function link_agents() {
  symlink "$SOURCE_DIR/agents" "$HOME/.claude/agents"
}

# ── symlink individual skills ───────────────────────────────────────────────
function link_skills() {
  local skills_dir="$HOME/.claude/skills"
  mkdir -p "$skills_dir"

  for skill_file in "$SOURCE_DIR/skills/"*.md(N); do
    local name=$(basename "$skill_file")
    symlink "$skill_file" "$skills_dir/$name"
  done
}

# ── symlink memory/ to project memory path ─────────────────────────────────
function link_memory() {
  local project_path=$(echo "$SOURCE_DIR" | sed 's|/|-|g')
  local memory_dest="$HOME/.claude/projects/$project_path/memory"

  mkdir -p "$(dirname "$memory_dest")"
  symlink "$SOURCE_DIR/memory" "$memory_dest"
  info "Memory path: $memory_dest"
}

# ── install plugins from settings.json enabledPlugins ──────────────────────
function install_plugins() {
  local settings="$SOURCE_DIR/config/settings.json"
  [[ -f "$settings" ]] || { warn "settings.json not found, skipping plugins"; return; }

  local plugins
  plugins=($(node -e "
    const s = require('$settings');
    const p = Object.keys(s.enabledPlugins || {});
    process.stdout.write(p.join('\n'));
  " 2>/dev/null))

  for plugin in "${plugins[@]}"; do
    [[ -z "$plugin" ]] && continue
    info "Plugin: $plugin"
    claude plugin install "$plugin" 2>/dev/null \
      || warn "$plugin: install failed or already installed"
  done
  success "Plugins done"
}

# ── run tool install scripts ────────────────────────────────────────────────
function install_tools() {
  for script in "$SOURCE_DIR/tools/install-"*(N); do
    [[ -x "$script" ]] || continue
    info "Running $(basename $script)..."
    "$script" || warn "$(basename $script) failed — check manually"
  done
}

# ── install repo git pre-commit hook ───────────────────────────────────────
function install_git_hook() {
  local src="$SOURCE_DIR/config/git-hooks/pre-commit-secret-scan"
  local dest="$SOURCE_DIR/.git/hooks/pre-commit"
  [[ -f "$src" ]] || return
  symlink "$src" "$dest"
  chmod +x "$src"
}

# ── write metadata ──────────────────────────────────────────────────────────
function write_metadata() {
  echo "$SOURCE_DIR" > "$HOME/.claude/.claude-config-dir"
  date +%s       > "$HOME/.claude/.last-update"
  success "Metadata written"
}

# ── main ────────────────────────────────────────────────────────────────────
check_deps
install_claude
link_config
link_hooks
link_agents
link_skills
link_memory
install_plugins
install_tools
install_git_hook
write_metadata

print ""
success "Claude config installed."
```

- [ ] **Step 2: Make executable and syntax-check**

```bash
chmod +x /home/james/projects/personal/claude-config/install
zsh -n /home/james/projects/personal/claude-config/install
```
Expected: no output (clean syntax)

- [ ] **Step 3: Commit**

```bash
git add install
git commit -m "rewrite install: idempotent symlinks, colour output, plugin bootstrap"
```

---

## Task 4: Write `update` Script

- [ ] **Step 1: Write update**

```zsh
#!/usr/bin/env zsh

SOURCE_DIR=${0:a:h}

info()    { print -P "%F{blue}[info]%f  $1" }
success() { print -P "%F{green}[ok]%f    $1" }
warn()    { print -P "%F{yellow}[warn]%f  $1" }

# git pull
function pull() {
  info "Pulling..."
  git -C "$SOURCE_DIR" pull || warn "git pull failed — continuing with local state"
}

# run legacy cleanup scripts for deprecated tools/plugins
function run_legacy() {
  local ran=0
  for script in "$SOURCE_DIR/legacy/uninstall-"*(N); do
    [[ -x "$script" ]] || continue
    info "Legacy cleanup: $(basename $script)..."
    "$script" || warn "$(basename $script) failed"
    ran=1
  done
  [[ $ran -eq 0 ]] && info "No legacy scripts"
}

# remove dangling symlinks in ~/.claude managed dirs
function clean_dangling() {
  local dirs=(
    "$HOME/.claude/skills"
    "$HOME/.claude/hooks"
    "$HOME/.claude/agents"
  )

  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir/"*(N); do
      if [[ -L "$f" && ! -e "$f" ]]; then
        rm "$f"
        info "Removed dangling: $f"
      fi
    done
  done
  success "Dangling symlinks cleaned"
}

# main
pull
run_legacy
clean_dangling

info "Syncing via install..."
"$SOURCE_DIR/install"
```

- [ ] **Step 2: Make executable and syntax-check**

```bash
chmod +x /home/james/projects/personal/claude-config/update
zsh -n /home/james/projects/personal/claude-config/update
```

- [ ] **Step 3: Commit**

```bash
git add update
git commit -m "add update script: pull + legacy cleanup + dangling symlinks + install"
```

---

## Task 5: Write `uninstall` Script

- [ ] **Step 1: Write uninstall**

```zsh
#!/usr/bin/env zsh

SOURCE_DIR=${0:a:h}

info()    { print -P "%F{blue}[info]%f  $1" }
success() { print -P "%F{green}[ok]%f    $1" }
warn()    { print -P "%F{yellow}[warn]%f  $1" }

# run tool + legacy uninstallers
function run_uninstallers() {
  for script in \
    "$SOURCE_DIR/tools/uninstall-"*(N) \
    "$SOURCE_DIR/legacy/uninstall-"*(N); do
    [[ -x "$script" ]] || continue
    info "$(basename $script)..."
    "$script" || warn "$(basename $script) failed"
  done
}

# remove all symlinks we created
function remove_symlinks() {
  local claude_dir="$HOME/.claude"

  # config files
  for f in CLAUDE.md RTK.md settings.json .mcp.json keybindings.json; do
    local dest="$claude_dir/$f"
    [[ -L "$dest" ]] && rm "$dest" && info "Removed $f"
  done

  # hooks we installed
  for hook_file in "$SOURCE_DIR/config/hooks/"*(N); do
    [[ -f "$hook_file" ]] || continue
    local dest="$claude_dir/hooks/$(basename $hook_file)"
    [[ -L "$dest" ]] && rm "$dest" && info "Removed hook $(basename $hook_file)"
  done

  # agents dir symlink
  [[ -L "$claude_dir/agents" ]] && rm "$claude_dir/agents" && info "Removed agents"

  # skills
  for skill_file in "$SOURCE_DIR/skills/"*.md(N); do
    local dest="$claude_dir/skills/$(basename $skill_file)"
    [[ -L "$dest" ]] && rm "$dest" && info "Removed skill $(basename $skill_file)"
  done

  # memory
  local project_path=$(echo "$SOURCE_DIR" | sed 's|/|-|g')
  local memory_dest="$HOME/.claude/projects/$project_path/memory"
  [[ -L "$memory_dest" ]] && rm "$memory_dest" && info "Removed memory symlink"

  # git pre-commit hook
  local pre_commit="$SOURCE_DIR/.git/hooks/pre-commit"
  [[ -L "$pre_commit" ]] && rm "$pre_commit" && info "Removed pre-commit hook"

  success "Symlinks removed"
}

# remove claude CLI
function remove_claude() {
  # native install
  if [[ -f "$HOME/.local/bin/claude" ]]; then
    rm -f "$HOME/.local/bin/claude"
    rm -rf "$HOME/.local/share/claude"
    info "Removed native claude binary"
  fi

  # npm install fallback
  if npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1; then
    npm uninstall -g @anthropic-ai/claude-code
    info "Removed npm claude package"
  fi
}

# nuke config dirs
function remove_config() {
  rm -rf "$HOME/.claude"
  rm -f  "$HOME/.claude.json"
  success "Removed ~/.claude and ~/.claude.json"
}

# main
run_uninstallers
remove_symlinks
remove_claude
remove_config

success "Claude fully uninstalled."
```

- [ ] **Step 2: Make executable and syntax-check**

```bash
chmod +x /home/james/projects/personal/claude-config/uninstall
zsh -n /home/james/projects/personal/claude-config/uninstall
```

- [ ] **Step 3: Commit**

```bash
git add uninstall
git commit -m "add uninstall script"
```

---

## Task 6: Write Session-Start Update Hook

This is a Claude `SessionStart` hook. It reads metadata written by `install` to check if the repo is stale (>12h) and run `./update`, and to warn if the repo has uncommitted changes.

**File:** `config/hooks/session-start-update-check`

- [ ] **Step 1: Write the hook**

```bash
#!/bin/bash
# SessionStart hook: auto-update if stale, remind if repo is dirty.
# Only runs after install has been executed (requires .claude-config-dir).

CONFIG_DIR_FILE="$HOME/.claude/.claude-config-dir"
[[ -f "$CONFIG_DIR_FILE" ]] || exit 0

CLAUDE_CONFIG_DIR=$(cat "$CONFIG_DIR_FILE")
[[ -d "$CLAUDE_CONFIG_DIR" ]] || exit 0

LAST_UPDATE_FILE="$HOME/.claude/.last-update"
STALE_SECONDS=$((12 * 3600))

# auto-update if stale
if [[ -f "$LAST_UPDATE_FILE" ]]; then
  LAST_UPDATE=$(cat "$LAST_UPDATE_FILE")
  NOW=$(date +%s)
  AGE=$((NOW - LAST_UPDATE))
  if [[ $AGE -ge $STALE_SECONDS ]]; then
    echo "claude-config: ${AGE}s since last update — running ./update"
    "$CLAUDE_CONFIG_DIR/update"
  fi
else
  date +%s > "$LAST_UPDATE_FILE"
fi

# dirty repo reminder
DIRTY=$(git -C "$CLAUDE_CONFIG_DIR" status --porcelain 2>/dev/null)
if [[ -n "$DIRTY" ]]; then
  echo "claude-config has uncommitted changes — commit and push before switching machines"
fi

exit 0
```

- [ ] **Step 2: Make executable and syntax-check**

```bash
chmod +x /home/james/projects/personal/claude-config/config/hooks/session-start-update-check
bash -n /home/james/projects/personal/claude-config/config/hooks/session-start-update-check
```

- [ ] **Step 3: Register the hook in settings.json**

The `SessionStart` hooks array in `config/settings.json` needs a new entry. Add it to the `startup` matcher's hooks array. Open `config/settings.json` and add to the `SessionStart` array:

```json
{
  "matcher": "startup",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/session-start-update-check"
    }
  ]
}
```

Add this as a new object in the `SessionStart` array (alongside the existing `startup` matcher block for `cbm-session-reminder`). The full `SessionStart` array should contain: the caveman activate hook (no matcher), the cbm-session-reminder entries (startup/resume/clear/compact matchers), and this new startup entry.

- [ ] **Step 4: Syntax-check settings.json is valid JSON**

```bash
node -e "JSON.parse(require('fs').readFileSync('./config/settings.json','utf8')); console.log('valid')"
```
Expected: `valid`

- [ ] **Step 5: Commit**

```bash
git add config/hooks/session-start-update-check config/settings.json
git commit -m "add session-start hook: auto-update and dirty-repo reminder"
```

---

## Task 7: Write Pre-Commit Secret Scan

Git `pre-commit` hook installed to `.git/hooks/pre-commit` by `./install`. Blocks commits if `config/settings.json` appears to contain API keys or tokens in the `env` block.

**File:** `config/git-hooks/pre-commit-secret-scan`

- [ ] **Step 1: Write the hook**

```bash
#!/bin/bash
# Pre-commit: block commits if config/settings.json env block contains secrets.

REPO_ROOT=$(git rev-parse --show-toplevel)
SETTINGS="$REPO_ROOT/config/settings.json"

[[ -f "$SETTINGS" ]] || exit 0

# only scan if settings.json is staged
git diff --cached --name-only | grep -q "config/settings.json" || exit 0

node - "$SETTINGS" << 'EOF'
const fs = require('fs');
const path = process.argv[1];
let data;
try { data = JSON.parse(fs.readFileSync(path, 'utf8')); } catch(e) { process.exit(0); }

const secretKeyPattern = /_KEY|_TOKEN|_SECRET|_PASSWORD|_API/i;
const secretValPattern = /^(sk-|ghp_|xoxb-|xoxp-|AKIA|ya29\.|AIza)/;

const env = data.env || {};
const suspicious = Object.entries(env)
  .filter(([k, v]) => secretKeyPattern.test(k) || secretValPattern.test(String(v)))
  .map(([k]) => k);

if (suspicious.length > 0) {
  console.error('ERROR: Possible secrets in config/settings.json env block:', suspicious.join(', '));
  console.error('Use ~/.zshrc or ~/.zshenv for secrets — settings.json is committed to git.');
  process.exit(1);
}
EOF
```

- [ ] **Step 2: Make executable and syntax-check**

```bash
chmod +x /home/james/projects/personal/claude-config/config/git-hooks/pre-commit-secret-scan
bash -n /home/james/projects/personal/claude-config/config/git-hooks/pre-commit-secret-scan
```

- [ ] **Step 3: Commit**

```bash
git add config/git-hooks/pre-commit-secret-scan
git commit -m "add pre-commit secret scan for settings.json env block"
```

---

## Tasks 8–11: Tool Scripts

> **These four tasks are independent — dispatch in parallel via `superpowers:dispatching-parallel-agents` if using subagent-driven development.**

---

### Task 8: rtk Install + Uninstall

**Files:** `tools/install-rtk`, `tools/uninstall-rtk` (replaces existing `tools/install-rtk`)

- [ ] **Step 1: Write install-rtk**

```zsh
#!/usr/bin/env zsh
# Install rtk — token-optimised Claude Code CLI proxy
# https://github.com/rtk-ai/rtk

if command -v rtk &> /dev/null; then
  echo "[ok]   rtk already installed"
  exit 0
fi

echo "[info] Installing rtk..."
http --download --output /tmp/rtk-install.sh \
  https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh \
  || { echo "[error] Failed to download rtk installer"; exit 1 }

chmod +x /tmp/rtk-install.sh
/tmp/rtk-install.sh || { echo "[error] rtk installer failed"; exit 1 }
rm -f /tmp/rtk-install.sh

rtk init -g || { echo "[error] rtk init -g failed"; exit 1 }
echo "[ok]   rtk installed"
```

- [ ] **Step 2: Write uninstall-rtk**

```zsh
#!/usr/bin/env zsh
# Remove rtk

if ! command -v rtk &> /dev/null; then
  echo "[ok]   rtk not installed, skipping"
  exit 0
fi

RTK_BIN=$(command -v rtk)
rm -f "$RTK_BIN"
echo "[ok]   rtk removed ($RTK_BIN)"
```

- [ ] **Step 3: Make executable, syntax-check both**

```bash
chmod +x tools/install-rtk tools/uninstall-rtk
zsh -n tools/install-rtk && zsh -n tools/uninstall-rtk
```

- [ ] **Step 4: Commit**

```bash
git add tools/install-rtk tools/uninstall-rtk
git commit -m "rewrite install-rtk with idempotency; add uninstall-rtk"
```

---

### Task 9: happy Install + Uninstall

**Files:** `tools/install-happy`, `tools/uninstall-happy`

- [ ] **Step 1: Write install-happy**

```zsh
#!/usr/bin/env zsh
# Install happy — mobile/web client for Claude Code
# https://github.com/slopus/happy

if command -v happy &> /dev/null; then
  echo "[ok]   happy already installed"
  exit 0
fi

echo "[info] Installing happy..."
npm install -g happy || { echo "[error] Failed to install happy"; exit 1 }
echo "[ok]   happy installed"
```

- [ ] **Step 2: Write uninstall-happy**

```zsh
#!/usr/bin/env zsh
# Remove happy

if ! command -v happy &> /dev/null; then
  echo "[ok]   happy not installed, skipping"
  exit 0
fi

npm uninstall -g happy
echo "[ok]   happy removed"
```

- [ ] **Step 3: Make executable, syntax-check**

```bash
chmod +x tools/install-happy tools/uninstall-happy
zsh -n tools/install-happy && zsh -n tools/uninstall-happy
```

- [ ] **Step 4: Commit**

```bash
git add tools/install-happy tools/uninstall-happy
git commit -m "add install/uninstall scripts for happy"
```

---

### Task 10: caveman Install + Uninstall

caveman is both a Claude plugin (`caveman@caveman` marketplace) and uses an external installer that sets up the hooks in `settings.json`.

**Files:** `tools/install-caveman`, `tools/uninstall-caveman`

- [ ] **Step 1: Write install-caveman**

```zsh
#!/usr/bin/env zsh
# Install caveman — token-efficient communication mode for Claude Code
# https://github.com/JuliusBrussee/caveman
# Installs the caveman plugin marketplace and runs the full installer,
# which also writes the caveman hook configs into settings.json.

echo "[info] Installing caveman..."
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh \
  | bash || { echo "[error] Caveman install failed"; exit 1 }

echo "[ok]   caveman installed"
echo "[info] Note: caveman installer updates settings.json hook paths for this machine."
echo "[info] Commit settings.json changes only if the plugin list changed, not hook paths."
```

- [ ] **Step 2: Write uninstall-caveman**

```zsh
#!/usr/bin/env zsh
# Remove caveman

echo "[info] Uninstalling caveman..."
npx -y github:JuliusBrussee/caveman -- --uninstall \
  || echo "[warn] caveman uninstall script may have failed — check manually"

echo "[ok]   caveman uninstalled"
```

- [ ] **Step 3: Make executable, syntax-check**

```bash
chmod +x tools/install-caveman tools/uninstall-caveman
zsh -n tools/install-caveman && zsh -n tools/uninstall-caveman
```

- [ ] **Step 4: Commit**

```bash
git add tools/install-caveman tools/uninstall-caveman
git commit -m "add install/uninstall scripts for caveman"
```

---

### Task 11: codebase-memory-mcp Install + Uninstall

**Files:** `tools/install-codebase-memory-mcp`, `tools/uninstall-codebase-memory-mcp`

- [ ] **Step 1: Write install-codebase-memory-mcp**

```zsh
#!/usr/bin/env zsh
# Install codebase-memory-mcp — code knowledge graph MCP server
# https://github.com/DeusData/codebase-memory-mcp

if command -v codebase-memory-mcp &> /dev/null; then
  echo "[ok]   codebase-memory-mcp already installed"
  exit 0
fi

echo "[info] Installing codebase-memory-mcp..."
curl -fsSL \
  https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh \
  | bash || { echo "[error] codebase-memory-mcp install failed"; exit 1 }

echo "[ok]   codebase-memory-mcp installed"
```

- [ ] **Step 2: Write uninstall-codebase-memory-mcp**

```zsh
#!/usr/bin/env zsh
# Remove codebase-memory-mcp
# Note: 'codebase-memory-mcp uninstall' removes config only; preserves databases.
# Remove the binary separately.

if ! command -v codebase-memory-mcp &> /dev/null; then
  echo "[ok]   codebase-memory-mcp not installed, skipping"
  exit 0
fi

codebase-memory-mcp uninstall || echo "[warn] uninstall command failed"
rm -f "$HOME/.local/bin/codebase-memory-mcp"
echo "[ok]   codebase-memory-mcp removed"
```

- [ ] **Step 3: Make executable, syntax-check**

```bash
chmod +x tools/install-codebase-memory-mcp tools/uninstall-codebase-memory-mcp
zsh -n tools/install-codebase-memory-mcp && zsh -n tools/uninstall-codebase-memory-mcp
```

- [ ] **Step 4: Commit**

```bash
git add tools/install-codebase-memory-mcp tools/uninstall-codebase-memory-mcp
git commit -m "add install/uninstall scripts for codebase-memory-mcp"
```

---

## Task 12: Update CLAUDE.md and readme.md

- [ ] **Step 1: Rewrite CLAUDE.md**

Replace `/home/james/projects/personal/claude-config/CLAUDE.md` with:

```markdown
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
| New custom hook | Add to `config/hooks/`, register in `config/settings.json` |
| Deprecate a tool | Delete `tools/install-<name>`, move `tools/uninstall-<name>` → `legacy/uninstall-<name>` |

## Security

**Do not add secrets to `config/settings.json` env block** — this file is committed to git. Use `~/.zshrc` or `~/.zshenv` for environment secrets instead. A pre-commit hook blocks commits if the env block looks like it contains API keys or tokens.

## Machine-specific notes

The caveman plugin installer writes machine-specific absolute node paths into `settings.json` hooks. When switching machines, run `./install` (which runs `tools/install-caveman`) to update these paths. Do not commit settings.json changes that only update the caveman hook node path.

## External tools

| Tool | Purpose |
|------|---------|
| [rtk](https://github.com/rtk-ai/rtk) | Token-optimised Claude CLI proxy |
| [ccstatusline](https://github.com/sirmalloc/ccstatusline) | Status line (managed via `statusLine` in settings.json, no install script) |
| [happy](https://github.com/slopus/happy) | Mobile/web client for Claude Code |
| [caveman](https://github.com/JuliusBrussee/caveman) | Token-efficient mode (also a Claude plugin) |
| [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) | Code knowledge graph MCP server |
```

- [ ] **Step 2: Update readme.md**

Replace the `readme.md` todos section with:

```markdown
# Claude Config

Cross-box shared Claude config and installers — like [zsh-config](https://github.com/jamescodesthings/zsh-config) but for Claude Code.

## Requirements

- `node` / `npx` / `npm`
- `http` (HTTPie) — used by the install script to download installers

## Install

```shell
git clone git@github.com:jamescodesthings/claude-config.git
cd claude-config
./install
```

## Update (after pulling on a new machine)

```shell
./update
```

## Uninstall

```shell
./uninstall   # removes all tools, symlinks, and claude itself
```

## How it works

`config/` files are symlinked to `~/.claude/`. `tools/install-*` scripts install external tools. `legacy/uninstall-*` scripts clean up deprecated tools on `./update`. See CLAUDE.md for the full reference.
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md readme.md
git commit -m "update CLAUDE.md and readme with new structure"
```

---

## Task 13: Wire Up and Verify

Manual verification that everything is wired correctly before push.

- [ ] **Step 1: Dry-run syntax check all scripts**

```bash
cd /home/james/projects/personal/claude-config
for f in install update uninstall tools/install-* tools/uninstall-* config/hooks/*; do
  [[ -f "$f" ]] && zsh -n "$f" 2>&1 | sed "s|^|$f: |"
done
for f in config/git-hooks/*; do
  [[ -f "$f" ]] && bash -n "$f" 2>&1 | sed "s|^|$f: |"
done
```
Expected: no output (all clean)

- [ ] **Step 2: Verify settings.json is valid JSON with expected structure**

```bash
node -e "
  const s = require('./config/settings.json');
  console.log('plugins:', Object.keys(s.enabledPlugins || {}).length);
  console.log('hooks:', Object.keys(s.hooks || {}).length);
  console.log('statusLine:', !!s.statusLine);
  console.log('session-start-update-check in hooks:', 
    JSON.stringify(s.hooks).includes('session-start-update-check'));
"
```
Expected: plugins count > 0, hooks count > 0, statusLine true, session-start-update-check true

- [ ] **Step 3: Check all tool scripts are executable**

```bash
ls -la tools/ | grep "^-rw" | awk '{print $NF}' 
```
Expected: empty output — all files in tools/ should be `-rwx` (executable)

If any show as non-executable:
```bash
chmod +x tools/install-* tools/uninstall-*
```

- [ ] **Step 4: Verify .gitignore has the runtime state entries**

```bash
grep -E "\.last-update|\.claude-config-dir" .gitignore
```
Expected: both lines present

- [ ] **Step 5: Final commit and push**

```bash
git status
git push
```

---

## Post-Implementation Notes

**caveman hook paths in settings.json:** The caveman installer writes `/home/james/.asdf/installs/nodejs/<version>/bin/node` as the hook command path. Task 1 normalises this to `node`. When `tools/install-caveman` runs on a new machine, it will re-write the path. Commit only when the plugin list in `enabledPlugins` changes, not when the hook path changes.

**ccstatusline:** No install script. It runs on-demand via `npx -y ccstatusline@latest` — the `statusLine.command` in `settings.json` handles it. Nothing to install or uninstall separately.

**Memory directory:** After install, `~/.claude/projects/<path>/memory/` is a symlink to the repo's `memory/` dir. Claude will write memory files there automatically. Commit them to sync across machines.
