<div align="center">
  <img src="docs/cover.svg" alt="Agent Forge" width="100%"/>

  <br/>

  [![License: MIT](https://img.shields.io/badge/License-MIT-CC785C?style=flat-square&logo=opensourceinitiative&logoColor=white)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Multi--Agent%20CLI-a855f7?style=flat-square&logo=anthropic&logoColor=white)](AGENTS.md)
  [![Shell](https://img.shields.io/badge/Shell-zsh%20%7C%20bash-3b82f6?style=flat-square&logo=gnubash&logoColor=white)](install)
  [![Last Commit](https://img.shields.io/github/last-commit/jamescodesthings/claude-config?style=flat-square&color=3fb950&logo=git&logoColor=white)](https://github.com/jamescodesthings/claude-config/commits/main)
</div>

---

# Agent Forge

**Agent Forge** is a unified multi-agent CLI orchestration framework and shared configuration manager. It standardizes system prompts, skills, memory, agents, lifecycle hooks, and shell aliases across **Claude Code**, **Antigravity CLI**, **OpenAI Codex**, and **GitHub Copilot**.

---

## Supported Agent CLIs

| Agent CLI | Launch Command | Shell Alias | Config Location | System Prompt |
|-----------|----------------|-------------|-----------------|---------------|
| **Claude Code** | `claude` | `cld` (`cldr` resume) | `~/.claude/` | `claude/config/CLAUDE.md` |
| **Antigravity** | `agy` | `aggy` (`aggyr` continue) | `~/.gemini/` | `antigravity/GEMINI.md` |
| **OpenAI Codex** | `codex` | `chat` (`chatr` resume) | `~/.codex/` | `codex/` |
| **GitHub Copilot** | `copilot` | `pilot` (`pilotr` continue) | `~/.copilot/` | `copilot/` |

---

## Quick Start

### Installation

```shell
git clone git@github.com:jamescodesthings/claude-config.git agent-forge
cd agent-forge
./install
```

`./install` creates required target directories, symlinks configuration files, decrypts WIP skills, imports Antigravity plugins, and adds shell alias sourcing (`AI_CONFIG_DIR`) to `~/.zshrc`.

### Syncing Updates

```shell
git pull && ./install
```

### Uninstallation

```shell
./uninstall
```

`./uninstall` removes all deployed symlinks from `~/.claude/` and `~/.gemini/`, strips `AI_CONFIG_DIR` and shell alias blocks from `~/.zshrc`, and cleans configuration directories.

---

## Shell Aliases (`zsh/aliases.zsh`)

| Alias | Command | Purpose |
|-------|---------|---------|
| `cld` | `claude --dangerously-skip-permissions` | Launch Claude Code CLI |
| `cldr` | `claude --resume --dangerously-skip-permissions` | Resume last Claude session |
| `aggy` | `agy --dangerously-skip-permissions` | Launch Antigravity CLI |
| `aggyr` | `aggy --continue` | Continue last Antigravity session |
| `chat` | `codex --dangerously-bypass-approvals-and-sandbox` | Launch Codex CLI |
| `chatr` | `codex resume --last ...` | Resume last Codex session |
| `pilot` | `copilot --allow-all` | Launch Copilot CLI |
| `pilotr` | `copilot --continue --allow-all` | Continue Copilot session |
| `cldm` | `claude-monitor` | Session token & cost monitor |

---

## Architecture & Workflows

### Model Selection Guidelines

- **Default Model (`gemini-3.6-flash`):** Used for standard coding, subagents, code review, and implementation tasks.
- **Pro Model (`gemini-3.1-pro`):** Used for complex multi-step reasoning, architecture decisions, novel debugging, and large refactors.
- **Flash-Lite Model (`gemini-3.6-flash-lite`):** Used for triage, file validation, routing, simple classification, and quick research.

### Session State & Handoff System

Agent Forge includes an automated session state tracking protocol stored in [`.state/CURRENT_STATE.md`](file:///Users/jamesmacmillan/projects/personal/claude-config/.state/CURRENT_STATE.md):
- **Session Startup:** Incoming agents inspect `.state/CURRENT_STATE.md` to restore task context.
- **Session Handoff:** Agents record progress and save timestamped snapshots to `.state/YYYY-MM-DD-HH-MM-<tool>.md`.

See [AGENTS.md](AGENTS.md) and [shared/system-prompt/workflow.md](shared/system-prompt/workflow.md) for full details.
