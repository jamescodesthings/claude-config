# AGENTS.md: Agent Forge Core Reference

**Agent Forge** is a unified multi-agent CLI orchestration framework and shared configuration manager. It standardizes system prompts, skills, memory, agents, lifecycle hooks, and shell aliases across multiple AI agent CLIs (Claude Code, Antigravity CLI, OpenAI Codex, and GitHub Copilot).

---

## Supported Agent CLIs

| Agent CLI | Launch Command | Shell Alias | Config Directory | Target Environment |
|-----------|----------------|-------------|------------------|-------------------|
| **Claude Code CLI** | `claude` | `cld` (`cldr` resume) | `claude/config/`, `claude/hooks/` | `~/.claude/` |
| **Antigravity CLI** | `agy` | `aggy` (`aggyr` continue) | `antigravity/config/`, `antigravity/hooks/` | `~/.gemini/` |
| **OpenAI Codex CLI** | `codex` | `chat` (`chatr` resume) | `codex/` | `~/.codex/` |
| **GitHub Copilot CLI** | `copilot` | `pilot` (`pilotr` continue) | `copilot/` | `~/.copilot/` |

---

## Installation & Management

```shell
make install            # Install or update all CLI configurations (re-run after git pull)
make claude             # Install Claude Code CLI configuration only
make antigravity        # Install Antigravity CLI configuration only
make uninstall          # Uninstall all CLI configurations
make uninstall-claude   # Uninstall Claude Code CLI configuration
make uninstall-antigravity # Uninstall Antigravity CLI configuration
```

### Where a sub-installer belongs

`claude/install` and `antigravity/install` each run every `install-*` script in **two** directories: `shared/tools/` and their own `<cli>/tools/`. So the placement rule is:

- `shared/tools/install-*`: only for things installed the same way for every CLI, and safe to run more than once per `make install` (e.g. `install-rtk`, `install-claude-monitor`, both guarded by `command -v`).
- `<cli>/tools/install-*`: anything CLI-specific. Superpowers and caveman both live here, because each installs by a different mechanism per CLI (`claude plugin install` vs `agy plugin install` vs `npx skills add`).

Putting a CLI-specific installer in `shared/tools/` is what previously left Claude Code without Superpowers: the script only ever called `agy plugin install`, but ran during both installs, so the Claude pass looked like it had done something and hadn't. Guard every sub-installer on the state it actually manages, never on a proxy (`command -v caveman` never passes: caveman is a plugin, not a binary).

Every sub-installer is install-or-update: absent means install, present means update to latest. There is no separate `make update`, deliberately. A split entry point lets the two halves drift, and the "already installed" early return then pins a version forever, which is how this repo ended up shipping stale tooling in the first place. Claude Code's own binary is the one exception: it self-updates, and the result of its last attempt is in `~/.claude/.last-update-result.json`.

### Shell Aliases (`zsh/aliases.zsh`)
When installed, `make install` adds the following sourcing block to `~/.zshrc`:
```zsh
export AI_CONFIG_DIR="$HOME/projects/personal/agent-forge"
[[ -f "$AI_CONFIG_DIR/zsh/aliases.zsh" ]] && source "$AI_CONFIG_DIR/zsh/aliases.zsh"
```

Available shell aliases:
- `cld`: launch Claude Code CLI (`claude --dangerously-skip-permissions`)
- `cldr`: resume last Claude session (`cld --resume`)
- `aggy`: launch Antigravity CLI (`agy --dangerously-skip-permissions`)
- `aggyr`: continue last Antigravity session (`aggy --continue`)
- `chat`: launch Codex CLI (`codex --dangerously-bypass-approvals-and-sandbox`)
- `chatr`: resume Codex session (`codex resume --last ...`)
- `pilot`: launch GitHub Copilot CLI (`copilot --allow-all`)
- `pilotr`: continue GitHub Copilot session (`copilot --continue --allow-all`)
- `cldm`: launch token/cost monitor (`claude-monitor`)

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

All agents operating within Agent Forge MUST adhere to the shared session state protocol defined in [`shared/system-prompt/workflow.md`](file:///Users/jamesmacmillan/projects/personal/agent-forge/shared/system-prompt/workflow.md):

1. Session startup, mandatory:
   - Inspect [`.state/CURRENT_STATE.md`](file:///Users/jamesmacmillan/projects/personal/agent-forge/.state/CURRENT_STATE.md) at startup before executing commands or beginning work.
   - Synchronize context on active tasks, completed steps, and open issues.

2. Session maintenance and state updates, mandatory:
   - Update [`.state/CURRENT_STATE.md`](file:///Users/jamesmacmillan/projects/personal/agent-forge/.state/CURRENT_STATE.md) whenever task status changes, at session end/handoff, or upon rate limit warnings/interruption.
   - Save a timestamped snapshot copy to `.state/YYYY-MM-DD-HH-MM-<tool>.md` (e.g. `.state/2026-08-09-14-25-antigravity.md`) at major milestones or session end.

3. Task tracking format:
   - Use standard markdown checkboxes: `- [ ]` pending, `- [/]` in progress, `- [x]` completed.

---

## Repository Layout

```
.
├── .state/              # Active session state & timestamped handoff snapshots
├── antigravity/         # Antigravity CLI module (config/, hooks/, rules/, scripts/, tools/, install, uninstall)
├── claude/              # Claude Code CLI module (config/, hooks/, scripts/, tools/, install, uninstall)
├── codex/               # OpenAI Codex CLI configuration
├── copilot/             # GitHub Copilot CLI configuration
├── docs/                # Architecture/planning docs, gitignored and local-only (never committed: sensitive-leak risk)
├── PROJECT_INIT.md      # Instructions for seeding/syncing another project's CLAUDE.md against these rules
├── PROJECT_INIT_CHANGELOG.md # Dated log of changes to the portable rule sections PROJECT_INIT.md syncs
├── shared/              # Cross-CLI shared assets (agents/, memory/, memory-wip/, memory-encrypted/, scripts/, skills/, skills-wip/, skills-encrypted/, system-prompt/, tools/)
│   ├── memory-wip/      # Encrypted WIP memories, gitignored plaintext, symlinked whole-dir like memory/
│   ├── memory-encrypted/ # Committed AES-256 ciphertext mirror of memory-wip/
│   └── tools/           # Encryption, key rotation, cross-CLI sub-installers (install-*), and shared library (lib)
├── zsh/                 # Unified shell aliases (aliases.zsh)
├── Makefile             # Unified Makefile targets (install, claude, antigravity, uninstall, etc.)
├── install              # Master installer script
├── uninstall            # Master uninstaller script
├── CLAUDE.md -> AGENTS.md # Root instruction symlink
└── AGENTS.md            # Root agent reference (this file)
```
