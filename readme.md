# Claude Config

Cross-box shared claude config and installers to keep things fairly in sync across boxes.

Like https://github.com/jamescodesthings/zsh-config but specifically for claude

## Requirements

- nodejs for npx and npm i -g on the host machine (required for happy, and some of the external tools).

## Install

```shell
# Clone the repo
git clone git@github.com:jamescodesthings/claude-config.git

# cd into it
cd claude-config

# run install
./install

# to update (todo: probably script this and add to zsh-config)
git pull # in the repo directory
./install # install any new tools
```
 - todo: Create a specific update command to uninstall anything we've dropped
 - todo: Add a way to tell claude in this repo to check for new config we are not tracking

# current custom skills
Any custom skills we have written are linked here

- todo: add the `review for signs of ai writing` skill we've just created, it should be in `~/.claude`
- todo: add a script and guidance to CLAUDE.md or the writing skills skill, to ln -s back here so that new skills we write are added.

# Current mailine tools in use

# Claude Plugins

These plugins are installed via the /plugin install in claude.

- superpowers
- claude-md-management
- code-review
- code-simplifier
- commit-commands
- context7
- frontend-design
- playwright
- skill-creator

# External Tools

These tools are installed outside of claude.

- https://github.com/rtk-ai/rtk
- https://github.com/sirmalloc/ccstatusline
- https://github.com/slopus/happy
- https://github.com/juliusbrussee/caveman
- https://github.com/DeusData/codebase-memory-mcp

# Shared Config

## Methodology
Config is shared by linking (ln -s) the files in this repo to the CLAUDE 

## Files

- `~/.claude/CLAUDE.md`
- todo: add config, settings, global memory for things that aren't in CLAUDE.md, anything that makes persisting between computers easier (without taking actual sessions).
