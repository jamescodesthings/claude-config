# PROJECT_INIT Changelog

Append-only log of changes to the **portable** sections of `claude/config/CLAUDE.md` (the ones `PROJECT_INIT.md` syncs into other projects — see that file for the full list and what's excluded).

**When you edit a portable section, add an entry here in the same commit.** This is what lets a sync in another project tell "this project's copy is just stale" (matches a version recorded below) from "this project deliberately diverged" (never matched anything we ever shipped) — without that record, `PROJECT_INIT.md`'s sync process has no fallback but to ask about everything, every time.

**Accuracy matters more than completeness here.** A wrong entry is worse than a missing one — it causes a sync elsewhere to make a wrong call with false confidence. If you're not certain a change actually touched a portable section (verify with `git show <commit> -- claude/config/CLAUDE.md`, not just the commit message), leave it out rather than guess.

Entry format: `- YYYY-MM-DD — Section name — what changed and why (one line)`

Newest first. Keep the full history — it's cheap, and a sync only ever reads the most recent ~100 entries into context.

---

- 2026-08-17 — Creating Skills & Memories — new section added: new skills/memories must be scaffolded into the WIP tier (`skill-new`/`memory-new`), never written directly into the public dirs; demote-and-scrub is the fix if one leaks through anyway (caught after `project-init` was created directly in public and had to be demoted)
- 2026-08-17 — Project initialization — reworded to not hardcode the project-init skill's name/path, since it's now WIP-tier and its fuzzed name isn't stable across demotions; `PROJECT_INIT.md` is the stable fallback
- 2026-08-17 — Global Memories — added the WIP-encrypted memory tier and the `memory-*`/`skill-*` command family (commits 74b0385, 42a13e7); graduate is human-only, assistant never runs it
- 2026-08-17 — CLAUDE.md/AGENTS.md new/updated project stub — Improved the stub to avoid it being output with comments, or inaccuracies.
- 2026-08-17 — CLAUDE.md/AGENTS.md - remove deprecated note on other ai tools.

*(This changelog started 2026-08-17. Earlier changes to `claude/config/CLAUDE.md` exist in git history but were not reliably reconstructable at a per-section level from commit messages alone — a first attempt at backfilling produced at least one factually wrong entry, caught by review, so it was dropped rather than published inaccurate. Reconstruct further back only from actual diffs (`git log --follow -- claude/config/CLAUDE.md`, then `git show <commit> -- claude/config/CLAUDE.md` per commit), not from commit subjects.)*
