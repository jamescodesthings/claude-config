# Antigravity Hooks, ADHD Mode, Caveman Mode & Repo Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Antigravity hooks, ADHD mode injection, Caveman mode installer handling, and establish full repo parity for memory/agents symlinks and global skills.

**Architecture:** Update hook shell scripts in `antigravity/hooks/` to follow Antigravity's JSON schema contract (`PreInvocation` with `injectSteps` and `Stop` with `decision`), repair skill path checks, update `tools/install-caveman` for core skills, and update `install` script to symlink global memory and agents for Antigravity.

**Tech Stack:** zsh / bash / jq / python3 / git

## Global Constraints

- Preserve all existing functionality for Claude Code CLI while adding/fixing Antigravity CLI support.
- Do not add unrequested caveman skills (`caveman-commit`, `caveman-review`, `caveman-compress`).
- Strictly adhere to Antigravity hook contract specifications (`PreInvocation` injects `injectSteps`, `Stop` returns `decision`).

---

### Task 1: Fix ADHD Mode Hook & Self-Care in Antigravity

**Files:**
- Modify: `antigravity/hooks/adhd-mode-inject-skill`
- Test: Manual execution test with JSON payload on stdin

**Interfaces:**
- Consumes: Antigravity `PreInvocation` stdin JSON (`{"conversationId": "..."}`)
- Produces: Antigravity `PreInvocation` stdout JSON (`{"injectSteps": [{"ephemeralMessage": "..."}]}`)

- [ ] **Step 1: Update skill path resolution and output schema in `antigravity/hooks/adhd-mode-inject-skill`**

Update `antigravity/hooks/adhd-mode-inject-skill` to locate `monsoons-rhonchial/SKILL.md` in `$HOME/.gemini/config/skills/monsoons-rhonchial/SKILL.md` (or `$HOME/.gemini/antigravity-cli/skills/monsoons-rhonchial/SKILL.md`), incorporate self-care nudges (water, lunch, dinner, bed), and format output to Antigravity `PreInvocation` schema:

```zsh
#!/usr/bin/env zsh
skill_file="$HOME/.gemini/config/skills/monsoons-rhonchial/SKILL.md"
[[ -r "$skill_file" ]] || skill_file="$HOME/.gemini/antigravity-cli/skills/monsoons-rhonchial/SKILL.md"
[[ -r "$skill_file" ]] || exit 0

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

body=$(awk 'BEGIN{fm=0} NR==1 && $0=="---" {fm=1; next} fm==1 && $0=="---" {fm=0; next} fm==0 {print}' "$skill_file")

now=$(TZ=Europe/London date +%s)
hhmm=$(TZ=Europe/London date +%H%M)
messages=()

if { [[ "$hhmm" > "1200" ]] || [[ "$hhmm" == "1200" ]]; } && [[ "$hhmm" < "1300" ]]; then
  messages+=("SELF-CARE: it's lunchtime. Go eat.")
fi

if { [[ "$hhmm" > "1700" ]] || [[ "$hhmm" == "1700" ]]; } && [[ "$hhmm" < "1800" ]]; then
  messages+=("SELF-CARE: sort dinner and feed the dogs.")
fi

if { [[ "$hhmm" > "2300" ]] || [[ "$hhmm" == "2300" ]]; } || [[ "$hhmm" < "0500" ]]; then
  messages+=("SELF-CARE: it's past 11pm. Go to bed.")
fi

self_care_text=""
if ((${#messages[@]} > 0)); then
  self_care_text=$(printf "\n\n%s" "${messages[@]}")
fi

context="ADHD mode (skill: monsoons-rhonchial) is ACTIVE for this session. Its rules are reproduced in full below and govern all conversation and any document written for James to read. Do not invoke the skill separately; it is already loaded. These rules persist for the whole session and are turned off only when James says \"stop adhd mode\" or \"normal mode\".

$body$self_care_text"

jq -n --arg ctx "$context" \
  '{injectSteps: [{ephemeralMessage: $ctx}]}'

exit 0
```

- [ ] **Step 2: Verify `adhd-mode-inject-skill` execution**

Run: `echo '{"conversationId":"test"}' | antigravity/hooks/adhd-mode-inject-skill | jq .`
Expected: Output containing `{ "injectSteps": [ { "ephemeralMessage": "ADHD mode (skill: monsoons-rhonchial) is ACTIVE..." } ] }`

- [ ] **Step 3: Commit**

```bash
git add antigravity/hooks/adhd-mode-inject-skill
git commit -m "fix(antigravity): fix ADHD mode hook skill path, output contract, and self-care nudges"
```

---

### Task 2: Fix Session Stop Hook Contract & Caveman Installer

**Files:**
- Modify: `antigravity/hooks/session-stop-memory-reminder`
- Modify: `tools/install-caveman`

- [ ] **Step 1: Fix `antigravity/hooks/session-stop-memory-reminder` output schema**

Update `antigravity/hooks/session-stop-memory-reminder` to return valid Antigravity `Stop` JSON:

```bash
#!/usr/bin/env bash
# Stop hook: remind Antigravity agent to save memory before session ends.
cat <<'EOF'
{
  "decision": "allow"
}
EOF
exit 0
```

- [ ] **Step 2: Update `tools/install-caveman` to handle core skills and config skills directory**

Update `tools/install-caveman` lines 79-90 to copy skills from `$HOME/.gemini/config/skills/` into `$HOME/.gemini/antigravity-cli/skills/` without erroring:

```zsh
info "installing caveman into antigravity"
npx skills add JuliusBrussee/caveman -a antigravity -g -s caveman -s caveman-help -s caveman-stats -y --copy &> /dev/null \
  || error "caveman install into antigravity failed"

parent_dir="$HOME/.gemini/antigravity-cli/skills"
mkdir -p "$parent_dir"
for skill in caveman caveman-help caveman-stats; do
  if [[ -d "$HOME/.gemini/config/skills/$skill" ]]; then
    cp -r "$HOME/.gemini/config/skills/$skill" "$parent_dir/$skill" &> /dev/null || true
  fi
done

success "caveman installed"
```

- [ ] **Step 3: Test `session-stop-memory-reminder` and `tools/install-caveman`**

Run: `echo '{}' | antigravity/hooks/session-stop-memory-reminder | jq .`
Expected: `{ "decision": "allow" }`

Run: `./tools/install-caveman`
Expected: `[ok]   caveman installed`

- [ ] **Step 4: Commit**

```bash
git add antigravity/hooks/session-stop-memory-reminder tools/install-caveman
git commit -m "fix(antigravity): correct Stop hook contract and fix caveman installer paths"
```

---

### Task 3: Fix Master Installer (`install` Script) for Antigravity Parity

**Files:**
- Modify: `install`

- [ ] **Step 1: Update `install` script to symlink global memory, agents, and set canonical skills path for Antigravity**

In `install` script `link_antigravity()` function:
1. Ensure `ANTIGRAVITY_SKILLS_DIR="$GEMINI_DIR/config/skills"`.
2. Add symlink for `shared/memory` to `$GEMINI_DIR/config/memory` (and `$ANTIGRAVITY_DIR/memory`).
3. Add symlink for `shared/agents` to `$GEMINI_DIR/config/agents` (and `$ANTIGRAVITY_DIR/agents`).
4. Ensure `install-superpowers` is executed in `install_tools`.

- [ ] **Step 2: Execute `./install` and verify all symlinks**

Run: `./install`
Expected: Successfully links config, hooks, skills, memory, and agents for both Claude and Antigravity.

Verify:
Run: `ls -la ~/.gemini/config/skills ~/.gemini/config/memory ~/.gemini/config/agents ~/.gemini/config/hooks.json`
Expected: All symlinks present and pointing to repo source.

- [ ] **Step 3: Commit**

```bash
git add install
git commit -m "feat(installer): establish full Antigravity parity for skills, memory, agents, and hooks"
```
