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

update:
	./shared/tools/update-all
.PHONY: update

uninstall:
	./uninstall
.PHONY: uninstall

uninstall-claude:
	./claude/uninstall
.PHONY: uninstall-claude

uninstall-antigravity:
	./antigravity/uninstall
.PHONY: uninstall-antigravity