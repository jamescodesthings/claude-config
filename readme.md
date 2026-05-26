<div align="center">
  <img src="docs/cover.svg" alt="claude-config" width="100%"/>

  <br/>

  [![License: MIT](https://img.shields.io/badge/License-MIT-CC785C?style=flat-square&logo=opensourceinitiative&logoColor=white)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Claude%20Code-a855f7?style=flat-square&logo=anthropic&logoColor=white)](https://claude.ai/code)
  [![Shell](https://img.shields.io/badge/Shell-zsh%20%7C%20bash-3b82f6?style=flat-square&logo=gnubash&logoColor=white)](install)
  [![Last Commit](https://img.shields.io/github/last-commit/jamescodesthings/claude-config?style=flat-square&color=3fb950&logo=git&logoColor=white)](https://github.com/jamescodesthings/claude-config/commits/main)
  [![Stars](https://img.shields.io/github/stars/jamescodesthings/claude-config?style=flat-square&color=febc2e&logo=github&logoColor=white)](https://github.com/jamescodesthings/claude-config)
</div>

---

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

## Sync after git pull

```shell
git pull && ./install
```

## Uninstall

```shell
./uninstall
```

## How it works

`config/` files are symlinked to `~/.claude/`. `hooks/` are symlinked individually into `~/.claude/hooks/`. `tools/install-*` scripts install external tools. `legacy/uninstall-*` cleans up deprecated tools on re-install. See CLAUDE.md for the full reference.

## Starting a new project

On first use in a new project Claude will create a `CLAUDE.md` with the right structure; stack, setup, test commands, and the `## Post-implementation checks` hook for post-implementation review.
