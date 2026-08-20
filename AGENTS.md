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
make install-debug      # Same, streaming captured third-party output to the console
make install-trace      # Same as --debug plus zsh xtrace
make logs               # List the last run's captured logs
make claude             # Install Claude Code CLI configuration only
make antigravity        # Install Antigravity CLI configuration only
make uninstall          # Remove both CLIs and every config directory they own
make uninstall-config   # Remove agent-forge's symlinks only, leave the CLIs installed
make uninstall-claude   # Uninstall Claude Code CLI configuration
make uninstall-antigravity # Uninstall Antigravity CLI configuration
```

### The CLI binaries

`claude/install` and `antigravity/install` each begin by installing or updating the CLI they configure, via `<cli>/tools/bootstrap-cli`. Present means `claude update` / `agy update`; absent means the vendor bootstrapper from `https://claude.ai/install.sh` / `https://antigravity.google/cli/install.sh`.

Those scripts are downloaded into `.cache/installers/` and run from there, never piped into a shell. The trust model is identical either way (vendor URL, vendor script), but this leaves the exact bytes that ran on disk for after-the-fact inspection, and refuses to execute a download that is not a shell script, which is what a truncated transfer or an HTML error page served with a 200 would look like. The cache is re-fetched every run, so it can never pin a stale installer.

`bootstrap-cli` is deliberately not named `install-*`: that glob would run it a second time.

### Installer output and logs

Every third-party command an installer runs goes through `run_logged` in `shared/tools/lib`. It captures both output streams to `.cache/logs/<run-id>/<label>.log`, closes stdin, and returns the command's own exit status, so the usual `run_logged label cmd || warn ...` idiom reads the same as a bare call.

The console therefore only ever carries this repo's own `[info]`/`[ok]`/`[warn]` lines. Vendor bootstrappers, `claude plugin install`, `agy plugin install`, `npx skills add`, `uv` and `brew` all write banners, spinners and progress bars in their own formatting, and interleaving that with agent-forge's output made the actual install steps unreadable. The previous fix was `&> /dev/null`, which cured the noise by destroying the evidence: a failing step reported that it had failed and nothing anywhere said why.

When a step fails, the tail of its output is printed inline, scoped to that step. Log files are appended to across every command a script runs, so `run_logged` records the file's line count before it starts and reports only from there; without that, the second failure in a script would show the first one's output alongside its own.

- One directory per run, named for a timestamp. The id is exported, so sub-installers, which are separate processes, all write into the same directory.
- `.cache/logs/latest` symlinks to the most recent run. `make logs` lists it.
- The last 10 runs are kept (`AGENT_FORGE_LOG_KEEP_RUNS`), pruned newest-first at the end of a run.
- `curl` diagnostics from `fetch_installer` land in `downloads.log` in the same directory rather than on the console.
- Success messages carry the version (`Claude Code CLI up to date: 2.1.237`). `cli_version` pulls the first dotted-numeric token out of `--version` output, because CLIs pad it with their own name and a build tag and `rtk up to date (rtk 0.45.0)` reads badly.

Two flags, accepted by `./install`, `./claude/install`, `./antigravity/install` and both uninstallers, and exported so they reach every child process:

- `--debug` streams captured output to the console as well as to the log. The failure tail is suppressed in this mode, since the output has already been seen.
- `--trace` implies `--debug` and adds `setopt xtrace`. Use it when the installer itself is the suspect rather than the thing it is installing.

Both follow the `AGENT_FORGE_ASSUME_YES` convention: set but falsey (`0`, `no`, `false`, `off`) counts as off.

Capturing output has one non-obvious consequence worth knowing. `claude plugin install` and `claude plugin update` document `-y` as **required when stdin or stdout is not a TTY**, which is now always the case, so both calls pass it. Without it, any plugin whose marketplace declares an install command fails on every run. `agy plugin install` takes no flags at all and is unaffected.

`prune_run_logs` deletes with `rm -rf`, so the log root gets its own gate, `validate_log_root`: `ROOT_DIR` must not be `/`, must actually contain `shared/tools/lib`, and `AGENT_FORGE_LOG_ROOT` must be exactly `$ROOT_DIR/.cache/logs`. `ROOT_DIR` comes from this library's own location and is normally airtight, but `cd "/../.."` succeeds and prints `/`, so an empty `LIB_DIR` would silently aim the logging code at `/.cache/logs`. macOS refuses to create that; a root-run Linux container would not.

There is no locking. Nothing needs one today: the run id carries the entry point's PID, so two concurrent `./install` runs get separate directories, and sub-installers within a run are invoked sequentially. Backgrounding the tool loop, or a wrapper exporting a fixed `AGENT_FORGE_RUN_ID` across parallel runs, would need a lock added first, because the per-step offset is computed per process and cannot see another writer.

Two zsh traps are worth knowing before editing this code. `setopt xtrace` inside a **function** is silently undone when that function returns, because zsh saves and restores the option across every call, which is why tracing is switched on with a bare `trace_enabled && setopt xtrace` at the top level of a script rather than by a helper that does both. And in a glob qualifier, `^` inverts the sense of every qualifier that follows it, so `*(N/^@On)` negates the sort as well as the symlink test: `prune_run_logs` uses `*(N/On^@)` and keeping `^@` last is load-bearing, not cosmetic. Getting it wrong deletes the newest runs and keeps the stale ones.

### Uninstall is a full purge

`make uninstall` exists so a completely clean install can be tested and retested, which only works if nothing survives it. It removes agent-forge's symlinks, runs every `uninstall-*` tool, then deletes the CLI binary and all of its state:

- Claude Code: `~/.claude/`, `~/.claude.json` and its backups and tmp files, `~/.local/share/claude/`, `~/.cache/claude/`, `~/Library/Caches/claude-cli-nodejs/`, and the `~/.local/bin/claude` launcher
- Antigravity: `~/.gemini/` (which contains `antigravity-cli/`), `~/.cache/antigravity/`, and the `~/.local/bin/agy` binary

Left alone on purpose: `~/Library/Application Support/Claude` is the Claude **desktop app**, a different product that happens to share a name, and `~/.claude-monitor` belongs to a separate tool with its own uninstaller. A CLI binary found outside `~/.local/bin` is reported and skipped rather than deleted, since agent-forge did not put it there.

Each half prints its exact path list and requires you to type `purge` before deleting anything. `--yes` skips the prompt; a non-interactive shell without `AGENT_FORGE_ASSUME_YES=1` always refuses, so an unattended run cannot wipe a machine. Set-but-falsey values (`0`, `no`, `false`, `off`) count as no. `--no-purge` (or `make uninstall-config`) strips the symlinks only, and an unrecognised flag is a hard error rather than a silent fall-through to the destructive default.

`CLAUDE_CONFIG_DIR` and `GEMINI_CONFIG_DIR` come from the ambient environment and feed straight into `rm -rf`, so `validate_purge_root` in `shared/tools/lib` checks them before anything is removed, including the symlink sweep. It refuses an empty value, a relative path (which would resolve against the caller's working directory), `/`, `$HOME`, any top-level directory, and any path containing the agent-forge repo, since deleting an ancestor of the repo would take this tool's own source with it. Trailing slashes are stripped: a trailing slash makes the kernel resolve through a symlink before `lstat`, which would empty the link's target instead of unlinking the link.

Two related habits in the same library. `purge_path` uses `rm -rf --` so a path starting with a dash is a path, never a flag. `info`/`warn`/`success`/`error` paint only their colour prefix with `print -P` and pass the message through `print -r`, because these take filenames and `print -P` performs command substitution under `prompt_subst`.

What the confirmation does not prove is that a human typed it: `[[ -t 0 ]]` establishes a terminal, and anything allocating a pty can answer. It is a guard against accident, not against an automated caller that means it.

Two things worth knowing before agreeing: purging Claude Code deletes `~/.claude/projects/`, which is every session transcript on the machine, and Google's standalone `gemini` CLI also keeps its config in `~/.gemini`, so on a machine with both, purging Antigravity takes that CLI's config with it.

### Where a sub-installer belongs

`claude/install` and `antigravity/install` each run every `install-*` script in **two** directories: `shared/tools/` and their own `<cli>/tools/`. So the placement rule is:

- `shared/tools/install-*`: only for things installed the same way for every CLI, and safe to run more than once per `make install` (e.g. `install-rtk`, `install-claude-monitor`, both guarded by `command -v`).
- `<cli>/tools/install-*`: anything CLI-specific. Superpowers and caveman both live here, because each installs by a different mechanism per CLI (`claude plugin install` vs `agy plugin install` vs `npx skills add`).

Putting a CLI-specific installer in `shared/tools/` is what previously left Claude Code without Superpowers: the script only ever called `agy plugin install`, but ran during both installs, so the Claude pass looked like it had done something and hadn't. Guard every sub-installer on the state it actually manages, never on a proxy (`command -v caveman` never passes: caveman is a plugin, not a binary).

Every sub-installer is install-or-update: absent means install, present means update to latest. That now includes the CLI binaries themselves, via `bootstrap-cli` above. There is no separate `make update`, deliberately. A split entry point lets the two halves drift, and the "already installed" early return then pins a version forever, which is how this repo ended up shipping stale tooling in the first place.

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
├── .cache/installers/   # Downloaded vendor CLI install scripts, gitignored, re-fetched every install
├── .cache/logs/         # Captured installer output, one dir per run, gitignored, last 10 kept
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
