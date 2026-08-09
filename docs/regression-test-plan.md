# Agent Forge — Multi-CLI Regression Test Plan

This document outlines the step-by-step verification protocol to regression test **Claude Code CLI** and **Antigravity CLI** configurations.

---

## 1. Installation & Symlink Infrastructure

| Test ID | Command | Expected Result | Pass/Fail |
|---------|---------|-----------------|-----------|
| **INST-01** | `make uninstall` | All symlinks in `~/.claude/` and `~/.gemini/` are removed cleanly. `~/.zshrc` sourcing block removed. | [ ] |
| **INST-02** | `make claude` | Installs Claude config: `CLAUDE.md`, `RTK.md`, `settings.json`, `statusline.sh`, `hooks/`, `memory/`, `agents/`, `skills/`. | [ ] |
| **INST-03** | `make antigravity` | Installs Antigravity config: `GEMINI.md`, `settings.json`, `hooks.json`, `statusline.sh`, `rules/`, `hooks/`, `memory/`, `agents/`, `skills/`. | [ ] |
| **INST-04** | `make install` | Full idempotent setup across both CLIs without error. `pre-commit` hook linked to `.git/hooks/`. | [ ] |

---

## 2. Antigravity CLI Verification

| Test ID | Feature | Test Action | Expected Result | Pass/Fail |
|---------|---------|-------------|-----------------|-----------|
| **AGY-01** | **Global System Prompt** | Launch `aggy` in a test project. | `~/.gemini/GEMINI.md` rules are loaded. Model defaults to `gemini-3.6-flash`. | [ ] |
| **AGY-02** | **ADHD Injection Hook** | Start an Antigravity prompt turn. | `PreInvocation` hook fires `adhd-mode-inject-skill` and injects ephemeral instructions. | [ ] |
| **AGY-03** | **Global RTK Rules** | Execute `rtk git status` or inspect loaded rules. | `~/.gemini/config/rules/antigravity-rtk-rules.md` is active; model uses `rtk` command proxy. | [ ] |
| **AGY-04** | **Statusline Quotas** | Inspect statusline output in chat UI. | Statusline displays model name, context %, and 5h/7d quota windows (`gemini-5h` & `gemini-weekly` or `3p-5h` & `3p-weekly`). | [ ] |
| **AGY-05** | **Session Stop Git Check** | Attempt to end session while uncommitted changes or unpushed commits exist. | `Stop` hook returns `"decision": "continue"` with git warning, requiring `git push`. | [ ] |
| **AGY-06** | **Superpowers Plugin** | Execute a complex multi-step task. | Superpowers skills (`brainstorming`, `writing-plans`, `subagent-driven-development`) load via `obra/superpowers`. | [ ] |

---

## 3. Claude Code CLI Verification

| Test ID | Feature | Test Action | Expected Result | Pass/Fail |
|---------|---------|-------------|-----------------|-----------|
| **CLD-01** | **Global System Prompt** | Launch `cld` in a test project. | `~/.claude/CLAUDE.md` and `@RTK.md` are active. Model selection (Sonnet/Opus/Haiku) applies. | [ ] |
| **CLD-02** | **Statusline** | Inspect Claude statusline. | Displays context window %, 5h quota, and 7d quota formatted cleanly. | [ ] |
| **CLD-03** | **Caveman Mode** | Run `/caveman` or say "use caveman". | Caveman mode activates; `caveman-stats` tracks token savings accurately. | [ ] |
| **CLD-04** | **Session Stop Hook** | End session with unpushed commits. | `session-stop-memory-reminder` warns about unpushed commits and memory updates. | [ ] |
| **CLD-05** | **Token Monitor (`cldm`)** | Run `cldm` in terminal. | `claude-monitor` launches and displays real-time spending & usage breakdown. | [ ] |

---

## 4. Encryption & Skill Pipeline Verification

| Test ID | Feature | Test Action | Expected Result | Pass/Fail |
|---------|---------|-------------|-----------------|-----------|
| **ENC-01** | **WIP Skill Decryption** | Run `shared/tools/decrypt`. | Decrypts files in `shared/skills-encrypted/` to `shared/skills-wip/`. | [ ] |
| **ENC-02** | **Pre-commit Lock** | Attempt to git stage plaintext in `shared/skills-wip/` directly. | `pre-commit` hook blocks direct staging, auto-encrypts to `shared/skills-encrypted/`. | [ ] |
| **ENC-03** | **Key Rotation** | Run `shared/tools/cycle-key`. | Rotates symmetric encryption key, updates `.env`, and re-encrypts ciphertext tree atomically. | [ ] |
