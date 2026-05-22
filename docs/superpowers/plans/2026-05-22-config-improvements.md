# Config Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add missing tool scripts (uv, claude-monitor, ccstatusline), fix codebase-memory-mcp post-install, tune the CBM gate to not block config/doc reads, add a session-stop memory reminder hook, and minor CLAUDE.md + skill polish.

**Architecture:** All changes are in the claude-config repo at `/home/james/projects/personal/claude-config`. Config is deployed via symlinks by `./install`. No tests exist for this repo (config-only, no-TDD rule applies). All commits go direct to `main`.

**Tech Stack:** zsh, bash, JSON (settings.json), Markdown (skills/agents/CLAUDE.md)

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `tools/install-uv` | Create | Install uv Python package manager |
| `tools/uninstall-uv` | Create | Remove uv |
| `tools/install-claude-monitor` | Create | Install claude-monitor via uv |
| `tools/uninstall-claude-monitor` | Create | Remove claude-monitor |
| `tools/install-ccstatusline` | Create | Write ccstatusline config from template |
| `tools/uninstall-ccstatusline` | Create | Remove ccstatusline config |
| `config/ccstatusline-settings.json` | Create | Tracked template (uses `__HOME__` placeholder) |
| `tools/install-codebase-memory-mcp` | Modify | Add `codebase-memory-mcp install` post-step |
| `config/hooks/cbm-code-discovery-gate` | Create | Improved gate: allow non-code file reads through |
| `config/hooks/session-stop-memory-reminder` | Create | Remind Claude to save memory at session end |
| `config/settings.json` | Modify | Register new hooks (session-stop-memory-reminder) |
| `config/CLAUDE.md` | Modify | Add verification-before-completion trigger |
| `docs/templates/project-CLAUDE.md` | Create | Template for new project CLAUDE.md files |
| `skills/security-code-review.md` | Modify | Trim description — naming note too long |

---

### Task 1: Add tools/install-uv + tools/uninstall-uv

**Files:**
- Create: `tools/install-uv`
- Create: `tools/uninstall-uv`

- [ ] **Step 1: Create install-uv**

```bash
cat > tools/install-uv << 'EOF'
#!/usr/bin/env zsh
# Install uv — fast Python package manager
# https://docs.astral.sh/uv/

if command -v uv &> /dev/null; then
  echo "[ok]   uv already installed"
  exit 0
fi

echo "[info] Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh \
  || { echo "[error] uv install failed"; exit 1 }

echo "[ok]   uv installed"
EOF
chmod +x tools/install-uv
```

- [ ] **Step 2: Create uninstall-uv**

```bash
cat > tools/uninstall-uv << 'EOF'
#!/usr/bin/env zsh
# Uninstall uv

if ! command -v uv &> /dev/null; then
  echo "[ok]   uv not installed"
  exit 0
fi

uv self uninstall --no-modify-path \
  || { echo "[warn] uv self uninstall failed — remove ~/.local/bin/uv manually"; exit 1 }
echo "[ok]   uv removed"
EOF
chmod +x tools/uninstall-uv
```

- [ ] **Step 3: Verify files are executable**

```bash
ls -la tools/install-uv tools/uninstall-uv
```
Expected: `-rwxr-xr-x` for both.

---

### Task 2: Add tools/install-claude-monitor + tools/uninstall-claude-monitor

**Files:**
- Create: `tools/install-claude-monitor`
- Create: `tools/uninstall-claude-monitor`

Note: `install-claude-monitor` runs after `install-uv` alphabetically? No — 'cl' < 'u', so claude-monitor runs BEFORE uv alphabetically. Script must self-install uv if missing.

- [ ] **Step 1: Create install-claude-monitor**

```bash
cat > tools/install-claude-monitor << 'EOF'
#!/usr/bin/env zsh
# Install claude-monitor — Claude Code usage monitoring tool
# https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor

# Ensure uv is available (prerequisite)
if ! command -v uv &> /dev/null; then
  echo "[info] uv not found — installing prerequisite..."
  SCRIPT_DIR=${0:a:h}
  "$SCRIPT_DIR/install-uv" || { echo "[error] uv install failed"; exit 1 }
  # Reload PATH for current shell
  export PATH="$HOME/.local/bin:$PATH"
fi

if uv tool list 2>/dev/null | grep -q "^claude-monitor"; then
  echo "[ok]   claude-monitor already installed"
  exit 0
fi

echo "[info] Installing claude-monitor..."
uv tool install claude-monitor \
  || { echo "[error] claude-monitor install failed"; exit 1 }

echo "[ok]   claude-monitor installed — run: claude-monitor"
EOF
chmod +x tools/install-claude-monitor
```

- [ ] **Step 2: Create uninstall-claude-monitor**

```bash
cat > tools/uninstall-claude-monitor << 'EOF'
#!/usr/bin/env zsh
# Uninstall claude-monitor

if ! command -v uv &> /dev/null; then
  echo "[ok]   uv not installed, claude-monitor not present"
  exit 0
fi

if ! uv tool list 2>/dev/null | grep -q "^claude-monitor"; then
  echo "[ok]   claude-monitor not installed"
  exit 0
fi

uv tool uninstall claude-monitor \
  || { echo "[error] uninstall failed"; exit 1 }
echo "[ok]   claude-monitor removed"
EOF
chmod +x tools/uninstall-claude-monitor
```

- [ ] **Step 3: Verify files are executable**

```bash
ls -la tools/install-claude-monitor tools/uninstall-claude-monitor
```
Expected: `-rwxr-xr-x` for both.

---

### Task 3: Add ccstatusline config tracking + install/uninstall scripts

ccstatusline runs via `npx -y ccstatusline@latest` (no binary install needed). What we track: its settings file at `~/.config/ccstatusline/settings.json`, which has a machine-specific hardcoded path (`commandPath`). Template uses `__HOME__` as placeholder; install script copies + patches to correct absolute path.

**Files:**
- Create: `config/ccstatusline-settings.json` (template with `__HOME__` placeholder)
- Create: `tools/install-ccstatusline`
- Create: `tools/uninstall-ccstatusline`

- [ ] **Step 1: Read current ccstatusline config to use as template**

```bash
cat ~/.config/ccstatusline/settings.json
```

- [ ] **Step 2: Create config/ccstatusline-settings.json template**

Copy the current config content, replace all occurrences of `/home/james` with `__HOME__`:

```bash
cat ~/.config/ccstatusline/settings.json | sed 's|/home/james|__HOME__|g' > config/ccstatusline-settings.json
```

Verify the placeholder is applied:
```bash
grep -c "__HOME__" config/ccstatusline-settings.json
```
Expected: at least 1 (the `commandPath` line).

- [ ] **Step 3: Create install-ccstatusline**

```bash
cat > tools/install-ccstatusline << 'EOF'
#!/usr/bin/env zsh
# Install ccstatusline config — status line for Claude Code
# Binary runs via 'npx -y ccstatusline@latest' (no install needed).
# This script deploys the tracked config template to ~/.config/ccstatusline/settings.json

SCRIPT_DIR=${0:a:h}
TEMPLATE="$SCRIPT_DIR/../config/ccstatusline-settings.json"
DEST="$HOME/.config/ccstatusline/settings.json"

[[ -f "$TEMPLATE" ]] || { echo "[error] template not found: $TEMPLATE"; exit 1 }

mkdir -p "$(dirname "$DEST")"

# Only overwrite if template is newer or dest doesn't exist
if [[ -f "$DEST" ]] && [[ "$DEST" -nt "$TEMPLATE" ]]; then
  echo "[ok]   ccstatusline config already up to date"
  exit 0
fi

sed "s|__HOME__|$HOME|g" "$TEMPLATE" > "$DEST" \
  || { echo "[error] failed to write $DEST"; exit 1 }

echo "[ok]   ccstatusline config written to $DEST"
EOF
chmod +x tools/install-ccstatusline
```

- [ ] **Step 4: Create uninstall-ccstatusline**

```bash
cat > tools/uninstall-ccstatusline << 'EOF'
#!/usr/bin/env zsh
# Uninstall ccstatusline config (leaves npx-run binary alone)

DEST="$HOME/.config/ccstatusline/settings.json"

if [[ ! -f "$DEST" ]]; then
  echo "[ok]   ccstatusline config not present"
  exit 0
fi

rm "$DEST" && echo "[ok]   ccstatusline config removed"
EOF
chmod +x tools/uninstall-ccstatusline
```

- [ ] **Step 5: Verify template exists and install script is executable**

```bash
ls -la tools/install-ccstatusline tools/uninstall-ccstatusline config/ccstatusline-settings.json
```

---

### Task 4: Fix install-codebase-memory-mcp — add post-install step

Current script only downloads the binary but doesn't run `codebase-memory-mcp install` to configure auto-indexing. Add post-install step.

**Files:**
- Modify: `tools/install-codebase-memory-mcp`

- [ ] **Step 1: Read current install-codebase-memory-mcp**

```bash
cat tools/install-codebase-memory-mcp
```

- [ ] **Step 2: Add post-install configuration step**

After the main install, add:

```bash
# After the existing install block, before the final echo:
echo "[info] Running codebase-memory-mcp install (configure auto-index)..."
codebase-memory-mcp install \
  || echo "[warn] codebase-memory-mcp install step failed — run manually to configure auto-indexing"
```

Full replacement content for `tools/install-codebase-memory-mcp`:

```bash
#!/usr/bin/env zsh
# Install codebase-memory-mcp — code knowledge graph MCP server
# https://github.com/DeusData/codebase-memory-mcp

if command -v codebase-memory-mcp &> /dev/null; then
  echo "[ok]   codebase-memory-mcp already installed"
else
  echo "[info] Installing codebase-memory-mcp..."
  curl -fsSL \
    https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh \
    | bash || { echo "[error] codebase-memory-mcp install failed"; exit 1 }
fi

echo "[info] Running codebase-memory-mcp install (configure auto-index)..."
codebase-memory-mcp install \
  || echo "[warn] codebase-memory-mcp post-install step failed — run 'codebase-memory-mcp install' manually to configure auto-indexing"

echo "[ok]   codebase-memory-mcp installed"
```

- [ ] **Step 3: Verify file**

```bash
cat tools/install-codebase-memory-mcp
```
Expected: `codebase-memory-mcp install` line present.

---

### Task 5: Add cbm-code-discovery-gate to config/hooks/ with improved logic

Problem: current gate (at `~/.claude/hooks/cbm-code-discovery-gate`, not tracked in repo) blocks ALL Read/Grep/Glob on first call per session — including reads of `.md`, `.json`, `.sh` config/doc files. This forces workarounds (using Bash/cat) for any config file read.

Fix: track the hook in `config/hooks/` so install manages it, and add logic to allow non-code files through without triggering the gate.

Approach: parse stdin JSON for `file_path` key (Read tool). If path ends with a non-code extension (`.md`, `.json`, `.yaml`, `.yml`, `.toml`, `.txt`, `.sh`, `.bash`, `.zsh`), let through. Everything else: first call per session blocks.

**Files:**
- Create: `config/hooks/cbm-code-discovery-gate`
- Note: settings.json already has `~/.claude/hooks/cbm-code-discovery-gate` registered — `link_hooks()` will symlink it; the registration check grep will find it (matches `hooks/cbm-code-discovery-gate`)

- [ ] **Step 1: Create improved hook**

```bash
cat > config/hooks/cbm-code-discovery-gate << 'HOOKEOF'
#!/bin/bash
# Gate hook: nudges Claude toward codebase-memory-mcp for code discovery.
# Blocks first source-code file discovery per session.
# Allows through: config/doc file reads (.md .json .yaml .toml .txt .sh etc.)
GATE=/tmp/cbm-code-discovery-gate-$PPID
find /tmp -name 'cbm-code-discovery-gate-*' -mtime +1 -delete 2>/dev/null

if [ -f "$GATE" ]; then
    exit 0
fi

# Allow through if this is a Read of a non-code file
INPUT=$(cat)
if echo "$INPUT" | grep -qE '"file_path"\s*:\s*"[^"]*\.(md|json|yaml|yml|toml|txt|sh|bash|zsh|env|gitignore|gitattributes|lock)"'; then
    exit 0
fi

touch "$GATE"
echo 'BLOCKED: For code discovery, use codebase-memory-mcp tools first: search_graph(name_pattern) to find functions/classes, trace_path() for call chains, get_code_snippet(qualified_name) to read source. If the graph is not indexed yet, call index_repository first. Fall back to Grep/Glob/Read only for text content search. If you need Grep, retry.' >&2
exit 2
HOOKEOF
chmod +x config/hooks/cbm-code-discovery-gate
```

- [ ] **Step 2: Verify hook exists and is executable**

```bash
ls -la config/hooks/cbm-code-discovery-gate && bash -n config/hooks/cbm-code-discovery-gate && echo "syntax ok"
```

- [ ] **Step 3: Confirm settings.json registration will match**

```bash
grep "cbm-code-discovery-gate" config/settings.json
```
Expected: line present (hook already registered in PreToolUse).

---

### Task 6: Add session-stop-memory-reminder hook

A lightweight Stop hook reminding Claude to save key decisions/discoveries to memory at session end. Replaces the removed `post-agent-reminder` Stop hook (which was a full 13-item checklist).

**Files:**
- Create: `config/hooks/session-stop-memory-reminder`
- Modify: `config/settings.json` — add Stop hook entry

- [ ] **Step 1: Create hook**

```bash
cat > config/hooks/session-stop-memory-reminder << 'EOF'
#!/bin/bash
# Stop hook: remind Claude to save memory before session ends.
echo "Session ending — if key decisions, constraints, or non-obvious feedback were shared this session, save them to project memory now (types: project, feedback, user, reference)."
exit 0
EOF
chmod +x config/hooks/session-stop-memory-reminder
```

- [ ] **Step 2: Add Stop hook registration to settings.json**

Read current settings.json hooks section:
```bash
python3 -c "import json; s=json.load(open('config/settings.json')); print(json.dumps(s.get('hooks',{}), indent=2))"
```

Add Stop section. The hooks object needs a `"Stop"` key with an array containing the hook command. Use Python to patch:

```bash
python3 << 'EOF'
import json

with open('config/settings.json', 'r') as f:
    settings = json.load(f)

hooks = settings.get('hooks', {})

stop_hook = {
    "hooks": [
        {
            "type": "command",
            "command": "~/.claude/hooks/session-stop-memory-reminder"
        }
    ]
}

# Add Stop hooks (append if already exists, otherwise create)
if 'Stop' not in hooks:
    hooks['Stop'] = [stop_hook]
else:
    # Check not already registered
    cmds = [h.get('hooks', [{}])[0].get('command', '') for h in hooks['Stop']]
    if not any('session-stop-memory-reminder' in c for c in cmds):
        hooks['Stop'].append(stop_hook)

settings['hooks'] = hooks

with open('config/settings.json', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print("Done")
EOF
```

- [ ] **Step 3: Verify settings.json is valid JSON with the new hook**

```bash
python3 -c "import json; s=json.load(open('config/settings.json')); print('Stop hooks:', json.dumps(s['hooks'].get('Stop'), indent=2))"
```
Expected: shows `session-stop-memory-reminder` command.

---

### Task 7: Update config/CLAUDE.md — add verification-before-completion trigger

**Files:**
- Modify: `config/CLAUDE.md`

- [ ] **Step 1: Add verification-before-completion to skill priority triggers**

Current triggers section ends with:
```
- Touching any third-party library, SDK, or API → `context7` to fetch current docs before implementing
```

Add after that line:
```
- Before claiming any implementation task complete → `verification-before-completion` skill
```

- [ ] **Step 2: Verify change**

```bash
grep "verification-before-completion" config/CLAUDE.md
```
Expected: line present.

---

### Task 8: Create project init template

Developers starting a new project need a `CLAUDE.md` template that works with this config system. Key need: the `## Post-implementation checks` section that `post-implementation-review` skill reads for project-specific checks.

**Files:**
- Create: `docs/templates/project-CLAUDE.md`

- [ ] **Step 1: Create template**

```bash
mkdir -p docs/templates
cat > docs/templates/project-CLAUDE.md << 'EOF'
# CLAUDE.md

[One sentence: what this project is and what it does.]

## Stack

[Languages, frameworks, key dependencies — the minimum needed to orient a new dev.]

## Local setup

```bash
# minimal setup commands
```

## Testing

```bash
# how to run tests
```

## Post-implementation checks

<!-- post-implementation-review skill reads this section and appends its checks to the standard ones -->
<!-- Add project-specific checks here. Examples: -->
<!-- - Run database migrations: `npm run migrate` -->
<!-- - Verify API contract: `npm run test:contract` -->
<!-- - Check bundle size: `npm run analyze` -->
EOF
```

- [ ] **Step 2: Verify file created**

```bash
cat docs/templates/project-CLAUDE.md
```

---

### Task 9: Trim security-code-review.md description

The description field is bloated with a naming-collision note. Trim to essentials.

**Files:**
- Modify: `skills/security-code-review.md`

- [ ] **Step 1: Read current description**

```bash
head -6 skills/security-code-review.md
```

- [ ] **Step 2: Replace frontmatter description with trimmed version**

Current (bloated):
```yaml
description: Check changed code for security vulnerabilities. Named security-code-review (not security-review) to avoid collision with the code-review plugin's built-in security-review command.
```

Replace with:
```yaml
description: Check changed code for security vulnerabilities. Reports CRITICAL/IMPORTANT/MINOR findings; fixes Critical and Important before proceeding.
```

---

### Task 10: Commit all changes

- [ ] **Step 1: Stage all changes**

```bash
git add tools/install-uv tools/uninstall-uv \
        tools/install-claude-monitor tools/uninstall-claude-monitor \
        tools/install-ccstatusline tools/uninstall-ccstatusline \
        config/ccstatusline-settings.json \
        tools/install-codebase-memory-mcp \
        config/hooks/cbm-code-discovery-gate \
        config/hooks/session-stop-memory-reminder \
        config/settings.json \
        config/CLAUDE.md \
        docs/templates/project-CLAUDE.md \
        skills/security-code-review.md
```

- [ ] **Step 2: Commit**

```bash
git commit -m "$(cat <<'EOF'
add tool scripts, tune cbm gate, add memory reminder hook

- New tools: uv, claude-monitor (via uv), ccstatusline config tracking
- Fix codebase-memory-mcp post-install: add 'codebase-memory-mcp install' step
- CBM gate: track in config/hooks/, allow .md/.json/.yaml reads through
- Add session-stop-memory-reminder Stop hook
- CLAUDE.md: add verification-before-completion trigger
- Add docs/templates/project-CLAUDE.md for new project init
- Trim security-code-review description

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>
EOF
)"
```

- [ ] **Step 3: Push**

```bash
git push
```

- [ ] **Step 4: Run ./install to deploy new hooks and tool scripts**

```bash
./install
```

Expected: new hook symlinks created, ccstatusline config written, uv + claude-monitor installed.

---

## Self-Review

**Spec coverage check:**
- ✅ uv install/uninstall scripts
- ✅ claude-monitor install/uninstall scripts (depends on uv, self-bootstraps)
- ✅ ccstatusline config tracking + template with `__HOME__` substitution
- ✅ codebase-memory-mcp post-install step
- ✅ cbm-code-discovery-gate: tracked + improved to allow config/doc reads
- ✅ session-stop-memory-reminder Stop hook
- ✅ verification-before-completion in CLAUDE.md skill triggers
- ✅ project init template
- ✅ security-code-review description trimmed

**No placeholder steps** — all steps have exact file content or exact commands.

**Ordering note:** `install-claude-monitor` self-bootstraps uv if missing (handles alphabetical ordering issue where 'cl' < 'u' means claude-monitor runs before uv in the tools loop).
