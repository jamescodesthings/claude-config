---
name: feedback-check-off-plan-tasks
description: "Mark tasks [x] in spec/plan markdown docs as each is completed — do not leave them unchecked"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b367eacd-e1d3-4e21-90e1-1727f1685a3e
---

When working from a plan or spec document (any `.md` file with `- [ ]` task lists), mark each task `[x]` immediately when it is done. Do not batch-update at the end or leave them unchecked.

**Why:** User had to prompt to get tasks checked off after work was complete in the pico-8 session. Plan docs are the source of truth for what's done — leaving boxes unchecked makes it impossible to resume correctly in future sessions.

**How to apply:**
- After each subagent completes its task, update the corresponding `[ ]` → `[x]` in the plan doc before moving to the next task
- Treat task checkbox updates as part of completing the task, not a cleanup step
- This applies to: specs in `docs/superpowers/specs/`, `todo.md`, any plan doc produced by writing-plans skill
- Commit the updated plan doc together with the implementation changes, not as a separate follow-up
