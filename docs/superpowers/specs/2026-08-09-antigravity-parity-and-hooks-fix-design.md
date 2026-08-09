---
title: Antigravity Hooks, ADHD Mode, Caveman Mode & Repo Parity Design
date: 2026-08-09
---

# Architecture & Component Updates

## Overview

Fix Antigravity hook contracts and path resolution to ensure **ADHD mode** (`monsoons-rhonchial`) and **Caveman mode** (`caveman`) load and run properly in Antigravity sessions, while establishing full CLI parity with Claude Code for global skills, memory, agents, and plugins.

---

## Key Components & Changes

### 1. ADHD Mode Injection Hook (`antigravity/hooks/adhd-mode-inject-skill`)
- **Path Resolution:** Update skill search path to `$HOME/.gemini/config/skills/monsoons-rhonchial/SKILL.md` with fallback to `$HOME/.gemini/antigravity-cli/skills/monsoons-rhonchial/SKILL.md`.
- **PreInvocation Contract:** Change output JSON payload from Claude format (`{hookSpecificOutput: ...}`) to Antigravity format:
  ```json
  {
    "injectSteps": [
      {
        "ephemeralMessage": "<ADHD mode prompt + rules>"
      }
    ]
  }
  ```
- **Self-Care Nudges:** Integrate time-based self-care logic (2.5h session, lunch 12:00-13:00, dinner 17:00-18:00, bed >23:00) into `PreInvocation` so nudges append to the prompt context.

### 2. Caveman Mode (`caveman`)
- **Core Skills Only:** Retain only `caveman`, `caveman-help`, and `caveman-stats` (excluding `caveman-commit`, `caveman-review`, and `caveman-compress` as requested).
- **Installer Fix:** Fix `tools/install-caveman` so it correctly locates installed skills in `$HOME/.gemini/config/skills/` without erroring on missing `$HOME/.agents/skills/`.

### 3. Session Stop Hook (`antigravity/hooks/session-stop-memory-reminder`)
- **Stop Contract:** Update stdout from plain text to valid Antigravity `Stop` JSON:
  ```json
  {
    "decision": "allow"
  }
  ```

### 4. Installer Script Parity (`install`)
- **Skills Directory:** Set `ANTIGRAVITY_SKILLS_DIR` to `$GEMINI_DIR/config/skills` (Antigravity's global customization root).
- **Global Memory & Agents:**
  - Symlink `shared/memory` -> `$GEMINI_DIR/config/memory` (and `$ANTIGRAVITY_DIR/memory`).
  - Symlink `shared/agents` -> `$GEMINI_DIR/config/agents` (and `$ANTIGRAVITY_DIR/agents`).
- **Automated Tool Execution:** Ensure `install-caveman` and `install-superpowers` run seamlessly during `./install`.

---

## Verification & Testing Strategy
1. **Hook Unit Test:** Execute `~/.gemini/config/hooks/adhd-mode-inject-skill` via shell with mock JSON input and verify valid `injectSteps` JSON output.
2. **Installer Test:** Run `./install` and verify symlinks in `~/.gemini/config/` for skills, memory, agents, and hooks.
3. **Session Verification:** Verify active prompt context and hook execution behavior.
