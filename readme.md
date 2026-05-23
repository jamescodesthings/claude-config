# Claude Config

Cross-box shared Claude Code configuration — skills, agents, hooks, and tool installers.

## Requirements

- `zsh` (Ubuntu: `sudo apt-get install zsh`)
- `node` / `npx` / `npm`
- `curl`

## Install

```shell
git clone git@github.com:jamescodesthings/claude-config.git
cd claude-config
./install
```

## Update

```shell
./update
```

## Uninstall

```shell
./uninstall
```

## How it works

`config/` files are symlinked to `~/.claude/`. `hooks/` are symlinked individually into `~/.claude/hooks/`. `tools/install-*` scripts install external tools. `legacy/uninstall-*` cleans up deprecated tools on `./update`. See CLAUDE.md for the full reference.

## Starting a new project

```shell
mkdir my-project && cd my-project
git init
claude init      # creates a project-level CLAUDE.md
claude           # open Claude and describe what you want to build
```

That's it. The global config (installed above) handles everything else:

- **Workflow** — brainstorming → plan → subagent-driven implementation runs automatically
- **Skills** — superpowers, code-review, frontend-design, etc. available in every project
- **Agents** — shared agent definitions picked up globally
- **Hooks** — code-discovery gate, session reminders, caveman mode all active

`claude init` generates a project CLAUDE.md from your codebase. Edit it to add project-specific context — stack, conventions, external systems. The global workflow in `~/.claude/CLAUDE.md` stays in effect for every project.

### Optional project setup

If you want plans and specs tracked in the repo:

```shell
mkdir -p docs/superpowers/{plans,specs}
```

Claude will write plans to `docs/superpowers/plans/` and specs to `docs/superpowers/specs/` automatically when using the planning workflow.
