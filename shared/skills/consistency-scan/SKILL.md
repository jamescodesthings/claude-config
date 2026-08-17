---
name: consistency-scan
description: Sweep working docs (task lists, drafts, state files, specs) for claims that no longer match reality, and reconcile or flag them
---

# Consistency Scan

Working docs drift from reality: a task list mentions work that's already done, a draft sits around after being sent, a state file's assessment is stale because something external changed. Left alone, these leftovers are what pile up into a mess. This skill sweeps for that drift on demand — it does not run automatically.

## Scope: what counts as "ours"

Anything the user or the assistant authored, or is actively shaping: task lists, state files, drafts (emails, letters, messages), specs, plans, code comments describing status. **Not** in scope: received material, external sources, anything already fixed/final (an email actually sent and archived is a record, not a working doc anymore — don't re-open it).

Default scan targets: `.state/`, any directory the project's CLAUDE.md names as holding drafts/working docs. Ask the user for the target set if neither is present — do not guess at an unfamiliar project's layout.

## Process

1. **Enumerate** in-scope docs.
2. **Extract claims** from each: checkboxes, TODO markers, explicit status lines ("draft", "sent", "in progress"), factual assertions the doc depends on.
3. **Cross-check** each claim against ground truth:
   - Git log/diff — is the code change this task describes actually merged?
   - Sibling working docs — do two docs disagree about the same fact?
   - The user, for anything external to the repo (an email actually sent, a legal/case development, a decision made outside this session) — never assume; ask.
4. **Bucket findings:**
   - **Stale-done** — task claims incomplete, evidence says done. Safe to auto-correct (tick the box).
   - **Stale-doc** — draft superseded or already actioned (sent, submitted). Propose archiving; don't auto-move/delete without confirmation if the doc is externally consequential (legal, financial, sent-to-a-third-party).
   - **Contradiction** — two working docs disagree. Surface both, ask which is current — do not silently pick one.
   - **External-change** — something outside the repo shifted the ground the doc's assessment stands on. Flag it; the user updates the assessment, you don't infer it.
5. **Apply.** Low-stakes, unambiguous corrections (checkbox ticks, dead-task removal) apply directly. Anything touching a draft meant for someone else, a legal/financial document, or an ambiguous match: report it, don't act.
6. **Report** a short summary: what changed, what's flagged for the user's call. No lectures on what was found and left alone — a name and one line per item is enough.

## Boundaries

- Never treat this as license to rewrite a doc's tone or restructure it — only claims that are provably stale get touched.
- A doc explicitly marked final/archived is out of scope, full stop.
- If scope is genuinely ambiguous (is this list a draft or a finished record?), ask once — don't scan speculatively.
