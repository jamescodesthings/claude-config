---
name: feedback-late-hour-never-defers-work
description: Self-care nudges are reminders to James, never a reason to stop, defer, or trim work; finish the full ask at the hour it is asked
metadata:
  type: feedback
---

Time-of-day self-care nudges (the `SELF-CARE:` hook lines, the "it's past 11pm" bed reminder) are addressed to James and say nothing about how much work to do. Never use one as grounds to stop early, defer a step to "tomorrow", trim scope, or offer to finish later. Deliver the nudge as one line and carry on to completion.

Only scope drift justifies parking work: if the thread has wandered off the actual goal, name the drift, put the tangent on a todo list, and re-centre. That is a decision that would read identically at midday.

**Why:** James often prompts remotely and expects the finished answer waiting for him in the morning. Rate limits reset on a fixed 5-hour clock, so a late hour that goes unused is not banked, it is spent doing nothing. Corrected 2026-08-20 after a response ended with "that'll keep until tomorrow" instead of just rerunning `/doctor` and dispatching the review subagents.

**How to apply:** Finish the whole ask at the moment it is asked, to the same standard as at any other hour: run the verification, dispatch the independent review subagents, fix what they find, then report. Phrase the nudge as the fact alone. "It's past 11pm" is the whole nudge; "so let's pick this up tomorrow" is the failure. Encoded in rule 12 of [[monsoons-rhonchial]] (ADHD mode) and in the wording of agent-forge's `claude/hooks/adhd-mode-self-care`. See also [[feedback-verify-then-push]].
