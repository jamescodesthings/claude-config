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

uninstall-claude:
	./claude/uninstall
.PHONY: uninstall-claude

uninstall-antigravity:
	./antigravity/uninstall
.PHONY: uninstall-antigravity