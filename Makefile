SHELL := zsh
.ONESHELL:
.SILENT:

install:
	./install
.PHONY: install

# Same install, with every captured third-party command streamed to the console
# as well as written to the run log.
install-debug:
	./install --debug
.PHONY: install-debug

# --debug plus zsh xtrace, for when the installer itself is the suspect rather
# than the thing it is installing.
install-trace:
	./install --trace
.PHONY: install-trace

# What the last run actually printed. Third-party installer output is captured
# to .cache/logs/<run-id>/ rather than the console; `latest` points at the most
# recent run.
logs:
	if [[ -d .cache/logs/latest ]]; then
		print -r -- "Latest run: $$(readlink .cache/logs/latest)"
		ls -1sh .cache/logs/latest
		print -r -- "Read one with: less .cache/logs/latest/<name>.log"
	else
		print -r -- "No installer logs yet: run make install."
	fi
.PHONY: logs

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