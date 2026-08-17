# PROJECT_INIT

Instructions for a Claude Code session running **in a different project's repo** to seed or sync that project's `CLAUDE.md`/`AGENTS.md` against agent-forge's canonical rules.

**How this gets invoked:** James points a fresh session at this file directly — e.g. "update project instructions from `~/projects/personal/agent-forge/PROJECT_INIT.md`". You don't need any agent-forge skill installed in the target project for this to work; read this file and follow it directly. There may also be a locally-decrypted WIP skill that triggers on the same kind of request and points back here — its name is fuzzed and not stable across demotions, so don't hardcode a name for it; if nothing triggers, this file is authoritative on its own.

## What's portable and what isn't

The **canonical source** is `claude/config/CLAUDE.md` in the agent-forge repo (the path James gives you, or `~/projects/personal/agent-forge/claude/config/CLAUDE.md` if he just says "agent-forge"). Read it fresh every time — don't rely on a cached copy from a prior sync.

**Portable** (sync these into any project to emphasise the rule at both levels): Global Workflow, No-Confirmation Rule, Skill Priority, Post-Implementation Review, Git Strategy, Model Selection, TDD, Scope Creep Guard, Dependency Changes, Flaky Tests, Creating Skills & Memories, Global Memories, Auto-Memory, Project initialization.

Also read `PROJECT_INIT_CHANGELOG.md` (same directory as this file) — the most recent ~100 entries. It records what changed in the portable sections and why. You'll use it during sync (below) to tell "this project's copy is just stale" from "there's no record of this ever matching, so I can't assume."

## Case A — new project, no CLAUDE.md (or a bare one)

1. Copy the portable sections from `claude/config/CLAUDE.md` wholesale into the target's `CLAUDE.md`/`AGENTS.md`.
2. Run the project-init WIP skill (if it triggers locally) for the project-specific layer this file doesn't cover: the project structure template (stack, local setup, testing, `## Post-implementation checks`) and project-memory-directory seeding. It lives in agent-forge's encrypted WIP tier (`shared/skills-wip/`, pending graduation), not at a fixed public path — if it doesn't trigger, ask James for the current path or replicate manually against the `## Project Memory Seeding` conventions in the canonical `CLAUDE.md`'s `Auto-Memory` section.
3. Done — no diffing needed, there's nothing to reconcile against.

## Case B — existing project, has its own CLAUDE.md/AGENTS.md

This is a **sync, not a copy**. The target may have project-specific sections that must survive untouched (e.g. skill overrides that only make sense for that project), and may be missing or diverged on portable sections for reasons ranging from "never synced" to "deliberately opted out."

For each portable section listed above:

1. **Not present in the target at all, and never mentioned in the changelog as added after the target's most recent relevant edit** → likely just never synced. Propose adding it; low-stakes, but still show what you're adding before writing it (this file governs another project's *behavior*, treat it with real-file caution).
2. **Present and byte-identical to the current canonical version** → nothing to do.
3. **Present but different from the current canonical version:**
   - Check `PROJECT_INIT_CHANGELOG.md` for that section. If the target's text matches (or closely matches) a **prior recorded version** of that section — it's stale, not a deliberate override. Propose updating it to current, citing the changelog entry that explains what changed and why.
   - If the target's text doesn't match anything ever recorded for that section — you can't tell whether it's a deliberate project-specific rewrite or an edit from before this changelog existed. **Ask.** Don't guess either way.
4. **Present in the target but not a recognized portable section at all** (no header match, no fuzzy match) → leave it alone, don't even ask. This is project scope — ubiquitous-robot's project-only skill overrides are the reference example; agent-forge has no opinion on them.

### The Q&A

Batch every ambiguous case (3b's "no match" branch, and any case 1 you're unsure about) into one question set rather than asking serially. For each: state the section name, show the target's current text and the canonical current text side by side (or summarized if long), and ask plainly — *"Is this project's version an intentional override, or should it be updated to match agent-forge's current rule?"* Never infer an answer from prose tone or how old the section looks. Apply only what's confirmed.

### After applying

- Update the target only in the sections actually confirmed — leave everything else (portable-but-skipped, and all project-specific content) byte-for-byte as it was.
- If the target project has its own state/changelog convention, note the sync happened there. Don't invent one if it doesn't have one.

## Keeping this working

Whoever edits a portable section in agent-forge's `claude/config/CLAUDE.md` appends a `PROJECT_INIT_CHANGELOG.md` entry in the same commit — see that file's header for the format. Skipping this doesn't break anything immediately, but it silently degrades every future sync back to "ask about everything," which is the whole failure mode this changelog exists to avoid.
