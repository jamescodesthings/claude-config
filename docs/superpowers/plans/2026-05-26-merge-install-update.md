# Merge install/update: idempotent cleanup in install

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move legacy cleanup and dangling symlink removal from `update` into `install`, so a plain `./install` is fully idempotent and handles cleanup — then simplify `update` to `git pull && ./install`.

**Architecture:** `install` gains `run_legacy()` and `clean_dangling()` called before the link functions. `update` strips to source lib.sh + git pull + exec install. No new files.

**Tech Stack:** zsh

---

## File Map

- Modify: `install` — add `run_legacy()` and `clean_dangling()`, call in main sequence
- Modify: `update` — strip to git pull + ./install wrapper

---

## Task 1: Add run_legacy and clean_dangling to install

**Files:**
- Modify: `install`

- [ ] **Step 1: Add run_legacy function**

In `install`, after `write_metadata()` definition and before `# ── main ──`, add:

```zsh
# ── run legacy cleanup scripts ──────────────────────────────────────────────
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

# ── remove dangling symlinks in ~/.claude managed dirs ──────────────────────
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
```

- [ ] **Step 2: Call them in the main sequence**

In `install`, update the `# ── main ──` section to call `run_legacy` and `clean_dangling` before the link functions:

```zsh
# ── main ────────────────────────────────────────────────────────────────────
check_deps
install_claude
run_legacy
clean_dangling
link_config
link_hooks
link_agents
link_skills
link_memory
install_plugins
install_tools
write_metadata

print ""
success "Claude config installed."
```

---

## Task 2: Simplify update

**Files:**
- Modify: `update`

- [ ] **Step 1: Replace update body**

Rewrite `update` to:

```zsh
#!/bin/sh
# Re-exec with zsh (required).
if [ -z "$ZSH_VERSION" ]; then
  exec zsh "$0" "$@"
fi

SOURCE_DIR=${0:a:h}

source "$SOURCE_DIR/tools/lib.sh"

info "Pulling latest changes..."
git -C "$SOURCE_DIR" pull || warn "git pull failed — continuing with local state"

"$SOURCE_DIR/install"
```

---

## Task 3: Syntax-check and commit

**Files:** `install`, `update`

- [ ] **Step 1: Syntax-check both scripts**

```bash
zsh -n /home/james/projects/personal/claude-config/install
zsh -n /home/james/projects/personal/claude-config/update
```

Expected: no output (clean)

- [ ] **Step 2: Commit and push**

```bash
git add install update
git commit -m "merge install/update: legacy cleanup and dangling symlink removal now run in install"
git push
```
