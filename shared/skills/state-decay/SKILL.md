---
name: state-decay
description: Prune stale timestamped state snapshots, pulling any unresolved tasks forward into CURRENT_STATE.md first
---

# State Decay

Applies to any `.state/` directory shaped as `CURRENT_STATE.md` (the "now" file) plus timestamped snapshot files (`YYYY-MM-DD-HH-MM-<tool>.md`). Git already keeps full history — a decayed snapshot is not lost, just no longer cluttering the working tree. Never gate this on the user; run it whenever asked, or as part of session-end handoff if the project's CLAUDE.md says to.

## Rule

**Never delete a snapshot with an unresolved item until that item is verified present in CURRENT_STATE.md.** Losing a task silently is worse than a cluttered `.state/` directory.

## Process

1. Read `CURRENT_STATE.md`.
2. List snapshot files oldest first.
3. If snapshot count is at or under the configured threshold (default 10), stop — nothing to do.
4. For each snapshot, oldest first, until back under the threshold:
   a. Extract every `- [ ]` / `- [/]` line.
   b. For each, check whether an equivalent task already exists in `CURRENT_STATE.md` — match by exact task text; if a match is ambiguous (reworded, partially overlapping), do not guess — ask the user which resolution is correct.
   c. Anything not already represented: append to `CURRENT_STATE.md` under a `## Next up` section (create it if missing), preserving `[ ]`/`[/]` state.
   d. Once every open item from the snapshot is represented in `CURRENT_STATE.md`, delete the snapshot file. `[x]` items need no carry-forward — they're just dropped.
5. Summarize what was pulled forward and what was deleted. Leave the commit to the user unless they've already told you to commit without asking.

## Failure modes this guards against

- **Task loss from threshold-based pruning** — a file that's merely old but has a stray open item nobody carried over. Step 4b/4c prevents this.
- **Task identity drift** — a task reworded between sessions won't string-match. Flag it rather than silently duplicating or dropping it.
- **Cross-project reuse** — this logic is not agent-forge-specific. Any repo with the same `.state/` shape (project-level or global) can use it as-is.
