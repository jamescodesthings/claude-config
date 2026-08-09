# Phase 1 Verification & Manual Testing Checklist: Antigravity CLI Integration

**Framework:** Agent Forge  
**Component:** Phase 1 — Antigravity CLI Integration  
**Date:** 2026-08-09  

---

## Overview

This checklist guides manual verification of the **Antigravity CLI (`agy`)** integration in Agent Forge. Following execution of `./install`, perform these four manual verification tests to confirm shell aliases, CLI health diagnostics, WIP skill loading, and session state handoff functionality.

---

## Prerequisites

- `./install` has been executed successfully in the `agent-forge` repository.
- Open a **new terminal tab or window** to ensure updated `.zshrc` aliases and environment variables are loaded.

---

## Test 1: Shell Aliases Verification (`aggy` & `aggyr`)

### Purpose
Verify that shell aliases defined in `zsh/aliases.zsh` are properly loaded into Zsh and invoke `agy` with expected CLI flags.

### Execution Steps
1. Reload Zsh profile (or open a new terminal tab):
   ```zsh
   source ~/.zshrc
   ```

2. Check alias definitions in the terminal:
   ```zsh
   alias aggy
   alias aggyr
   ```
   **Expected Output:**
   ```text
   aggy='agy --dangerously-skip-permissions'
   aggyr='aggy --continue'
   ```

3. Launch Antigravity CLI via alias:
   ```zsh
   aggy
   ```
   - Confirm CLI starts immediately without prompting for execution permissions.
   - Exit the CLI session (`/exit` or `Ctrl+D`).

4. Test session continuation alias:
   ```zsh
   aggyr
   ```
   - Confirm CLI launches in session resume/continue mode.
   - Exit the CLI session.

### Pass Criteria
- [ ] `alias aggy` returns `agy --dangerously-skip-permissions`.
- [ ] `alias aggyr` returns `aggy --continue`.
- [ ] `aggy` launches Antigravity CLI skipping permission prompts.
- [ ] `aggyr` launches Antigravity CLI in session continuation mode.

---

## Test 2: Antigravity Health Validation (`agy doctor`)

### Purpose
Validate system configuration, symlinks, and environment health using Antigravity's built-in `doctor` command.

### Execution Steps
1. Execute the diagnostic command:
   ```zsh
   agy doctor
   ```

2. Review diagnostic output to verify:
   - Target configuration directory resolves to `~/.gemini/`.
   - `GEMINI.md` system prompt and `settings.json` are present and valid.
   - Active plugins registered in `~/.gemini/plugins/` (including `plugin.json`).
   - Shared skill symlinks in `~/.gemini/skills/` and `~/.gemini/skills-wip/` resolve cleanly without broken targets.

### Pass Criteria
- [ ] `agy doctor` runs and completes with exit status 0 (no fatal errors).
- [ ] Config files and symlinks under `~/.gemini/` report healthy status.
- [ ] Plugin and skill directories are recognized by the doctor diagnostic.

---

## Test 3: System Prompt & WIP Skill Trigger Verification

### Purpose
Verify that Antigravity loads system instructions from `GEMINI.md` and correctly identifies and triggers WIP skills (such as `monsoons-rhonchial`).

### Execution Steps
1. Run a prompt test triggering the WIP skill:
   ```zsh
   aggy -p "Test monsoons-rhonchial skill"
   ```

2. Observe response output:
   - Verify the agent recognizes `monsoons-rhonchial` from `~/.gemini/skills-wip/monsoons-rhonchial/SKILL.md`.
   - Confirm the agent follows prompt instructions adhering to `GEMINI.md` formatting and operational rules.

### Pass Criteria
- [ ] `aggy -p` command executes successfully.
- [ ] Agent recognizes and triggers the `monsoons-rhonchial` WIP skill.
- [ ] System prompt rules (`GEMINI.md`) govern the agent response.

---

## Test 4: Session State Handoff Verification (`.state/CURRENT_STATE.md`)

### Purpose
Verify that Antigravity inspects and synchronizes session state from `.state/CURRENT_STATE.md` at session startup in compliance with `shared/system-prompt/workflow.md`.

### Execution Steps
1. Verify `.state/CURRENT_STATE.md` exists and contains active task tracking details.
2. Prompt Antigravity to query active state:
   ```zsh
   aggy -p "What is the current active task and session status recorded in .state/CURRENT_STATE.md?"
   ```
3. Inspect agent response:
   - Confirm the agent reads `.state/CURRENT_STATE.md`.
   - Confirm accurate report of current task status, completed items, and active session context.

### Pass Criteria
- [ ] Antigravity reads `.state/CURRENT_STATE.md` at session startup.
- [ ] Agent correctly reports current session handoff status and active task details.

---

## Verification Sign-Off Table

| Test | Description | Result | Date | Notes |
|------|-------------|--------|------|-------|
| 1 | Shell Aliases (`aggy`, `aggyr`) | [ ] Pass / [ ] Fail | | Tested in new Zsh tab |
| 2 | `agy doctor` Diagnostics | [ ] Pass / [ ] Fail | | Checked `~/.gemini` symlinks |
| 3 | System Prompt & WIP Skill Trigger | [ ] Pass / [ ] Fail | | Verified `monsoons-rhonchial` trigger |
| 4 | State Handoff (`CURRENT_STATE.md`) | [ ] Pass / [ ] Fail | | Verified state file reading |

---
