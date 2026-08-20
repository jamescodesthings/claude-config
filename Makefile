SHELL := zsh
.ONESHELL:
.SILENT:

install:
	./install
.PHONY: install

claude:
	./claude/install
.PHONY: claude

antigravity:
	./antigravity/install
.PHONY: antigravity

uninstall:
	./uninstall
.PHONY: uninstall

# Symlinks only: leaves both CLI binaries and their state in place.
uninstall-config:
	./uninstall --no-purge
.PHONY: uninstall-config

uninstall-claude:
	./claude/uninstall
.PHONY: uninstall-claude

uninstall-antigravity:
	./antigravity/uninstall
.PHONY: uninstall-antigravity