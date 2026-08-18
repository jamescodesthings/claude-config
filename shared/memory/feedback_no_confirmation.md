---
name: feedback-no-confirmation
description: Never pause for confirmation or review gates: crack on unless genuine blocker or irreversible action
metadata:
  type: feedback
---

Never pause to ask the user to review, approve, or confirm between workflow steps, even when a skill has an explicit review gate (e.g. brainstorming's "user reviews spec before proceeding", writing-plans' "user approves plan").

**Why:** User explicitly corrected this multiple times. The back-and-forth is wasteful. Skills are guidance, not gates. The no-confirmation rule in CLAUDE.md takes precedence over any skill's review checkpoint.

**How to apply:**
- After writing a spec: proceed directly to writing-plans, do not ask user to review
- After writing a plan: proceed directly to execution, do not ask user to approve
- After completing tasks: proceed directly to next step, do not summarise and wait
- Only stop for: genuine blockers (missing credential, merge conflict, scope-changing ambiguity), or irreversible/destructive actions
- User can interrupt at any time if they want to redirect: that's their job, not yours to prompt for
- Exception confirmed 2026-08-17: a security/architecture fork with real blast-radius consequences (e.g. "reuse this encryption key across content-types or use a separate one?", "fuzz these filenames or not?") is worth one batched AskUserQuestion before building: user answered readily, no pushback. This is not the same as a workflow review gate; it's a decision genuinely his to make. Batch multiple such forks into one question set rather than asking serially.
