# Claude Config

Cross-box shared Claude config and installers — like [zsh-config](https://github.com/jamescodesthings/zsh-config) but for Claude Code.

## Requirements

- `node` / `npx` / `npm`
- `http` (HTTPie) — used by the install script to download installers

## Install

```shell
git clone git@github.com:jamescodesthings/claude-config.git
cd claude-config
./install
```

## Update (after pulling on a new machine)

```shell
./update
```

## Uninstall

```shell
./uninstall   # removes all tools, symlinks, and claude itself
```

## How it works

`config/` files are symlinked to `~/.claude/`. `tools/install-*` scripts install external tools. `legacy/uninstall-*` scripts clean up deprecated tools on `./update`. See CLAUDE.md for the full reference.
