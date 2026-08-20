---
name: feedback-verify-then-push
description: The hold-everything-until-manual-review rule is relaxed; verify no sensitive content is going up, then commit and push without waiting
metadata:
  type: feedback
---

The standing "do not commit or push until James has manually reviewed" instruction was a guard rail, not a permanent rule. As of 2026-08-20 it is relaxed: verify the diff yourself, have an independent subagent verify it too, and if both come back clean, commit and push.

**Why:** the guard existed to catch one specific failure, a Sonnet session committing WIP skills into the public tier as production skills, back when the only guidance against that was implicit in the skill's own description. That rule is now explicit in `CLAUDE.md` ("Creating Skills & Memories", WIP-first), so the blanket hold is redundant.

**How to apply:** before any push to the public agent-forge repo, confirm no WIP plaintext, no `docs/`, no `.env`, no tokens, and no machine-specific secrets are in the diff, using the [[secrets-check]] skill plus a separate reviewer agent. Clean means push, per [[feedback-always-push]]. Still never run `skill-graduate`/`memory-graduate`: see [[feedback-graduate-is-human-only]]. Still ask before genuinely destructive local actions such as agent-forge's `make uninstall` purge.
