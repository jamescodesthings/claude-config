# AGENTS.md — Agent Forge Core Reference

**Agent Forge** is a unified multi-agent CLI orchestration framework and shared configuration manager. It standardizes system prompts, skills, memory, agents, lifecycle hooks, and shell aliases across multiple AI agent CLIs.

---

## Supported Agent CLIs

| Agent CLI | Launch Command | Shell Alias | Config Directory | Target Environment |
|-----------|----------------|-------------|------------------|-------------------|
| **Claude Code CLI** | `claude` | `cld` (`cldr` resume) | `claude/config/`, `claude/hooks/` | `~/.claude/` |
| **Antigravity CLI** | `agy` | `aggy` (`aggyr` continue) | `antigravity/` | `~/.gemini/` |
| **OpenAI Codex CLI** | `codex` | `chat` (`chatr` resume) | `codex/` | `~/.codex/` |
| **GitHub Copilot CLI** | `copilot` | `pilot` (`pilotr` continue) | `copilot/` | `~/.copilot/` |

---

## Installation & Management

```shell
./install          # Bootstrap or sync configuration (idempotent, re-run after git pull)
./uninstall        # Complete cleanup: removes symlinks, shell aliases, and config dirs
```

### Shell Aliases (`zsh/aliases.zsh`)
When installed, `./install` adds the following sourcing block to `~/.zshrc`:
```zsh
export AI_CONFIG_DIR="$HOME/projects/personal/agent-forge"
[[ -f "$AI_CONFIG_DIR/zsh/aliases.zsh" ]] && source "$AI_CONFIG_DIR/zsh/aliases.zsh"
```

Available shell aliases:
- **`cld`**: Launch Claude Code CLI (`claude --dangerously-skip-permissions`)
- **`cldr`**: Resume last Claude session (`cld --resume`)
- **`aggy`**: Launch Antigravity CLI (`agy --dangerously-skip-permissions`)
- **`aggyr`**: Continue last Antigravity session (`aggy --continue`)
- **`chat`**: Launch Codex CLI (`codex --dangerously-bypass-approvals-and-sandbox`)
- **`chatr`**: Resume Codex session (`codex resume --last ...`)
- **`pilot`**: Launch GitHub Copilot CLI (`copilot --allow-all`)
- **`pilotr`**: Continue GitHub Copilot session (`copilot --continue --allow-all`)
- **`cldm`**: Launch token/cost monitor (`claude-monitor`)

---

## Model Selection Guidelines

Choose models based on task complexity and reasoning requirements:

| Task / Purpose | Model Selection | Description |
|----------------|-----------------|-------------|
| **Default Implementation** | `gemini-3.6-flash` | Standard coding, code review, subagent execution, unit testing, and general implementation tasks. |
| **Complex Reasoning & Architecture** | `gemini-3.1-pro` | Architecture decisions, complex multi-step reasoning, novel debugging, large code refactors, and system design. |
| **Routing & Triage** | `gemini-3.6-flash-lite` | Task routing, triage, file validation, simple text extraction, classification, and quick research lookups. |

---

## Session State & Handoff System

All agents operating within Agent Forge MUST adhere to the shared session state protocol defined in [`shared/system-prompt/workflow.md`](file:///Users/jamesmacmillan/projects/personal/claude-config/shared/system-prompt/workflow.md):

1. **Session Startup (Mandatory):**
   - Inspect [`.state/CURRENT_STATE.md`](file:///Users/jamesmacmillan/projects/personal/claude-config/.state/CURRENT_STATE.md) at startup before executing commands or beginning work.
   - Synchronize context on active tasks, completed steps, and open issues.

2. **Session Maintenance & State Updates (Mandatory):**
   - Update [`.state/CURRENT_STATE.md`](file:///Users/jamesmacmillan/projects/personal/claude-config/.state/CURRENT_STATE.md) whenever task status changes, at session end/handoff, or upon rate limit warnings/interruption.
   - Save a timestamped snapshot copy to `.state/YYYY-MM-DD-HH-MM-<tool>.md` (e.g. `.state/2026-08-09-14-25-antigravity.md`) at major milestones or session end.

3. **Task Tracking Format:**
   - Use standard markdown checkboxes: `- [ ]` Pending, `- [/]` In progress, `- [x]` Completed.

---

## Repository Layout

```
.
├── .state/              # Active session state & timestamped handoff snapshots
├── 00-tools/            # Skill encryption, decryption, and pre-commit hooks
├── antigravity/         # Antigravity CLI config (GEMINI.md, settings.json, hooks/, plugin.json)
├── claude/              # Claude Code CLI config (CLAUDE.md, RTK.md, settings.json, hooks/, scripts/)
├── codex/               # OpenAI Codex CLI configuration
├── copilot/             # GitHub Copilot CLI configuration
├── docs/                # Architecture design docs & specs
├── shared/              # Cross-CLI shared assets (skills/, skills-wip/, agents/, memory/, system-prompt/)
├── zsh/                 # Unified shell aliases (aliases.zsh)
├── install              # Master installer script
├── uninstall            # Master uninstaller script
└── AGENTS.md            # Root agent reference (this file)
```
