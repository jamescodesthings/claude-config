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
/path/to/claude-config/new-project   # git init + CLAUDE.md from template
claude                                # describe what you want to build
```

Or if you've already got a directory:

```shell
cd existing-project
/path/to/claude-config/new-project
```

`new-project` does two things: `git init` (if needed) and copies `docs/templates/project-CLAUDE.md` to `./CLAUDE.md`. Fill in the template — stack, local setup, test commands — before opening Claude.

The global config handles everything else:

- **Workflow** — brainstorming → plan → subagent-driven implementation runs automatically
- **Skills** — superpowers, code-review, frontend-design, etc. available in every project
- **Hooks** — code-discovery gate, session reminders, caveman mode all active
- **Post-implementation checks** — the `## Post-implementation checks` section in your CLAUDE.md is read by the `post-implementation-review` skill; add project-specific checks there

Plans and specs are written to `docs/superpowers/plans/` and `docs/superpowers/specs/` automatically.
