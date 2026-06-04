---
name: feedback-always-push
description: "After committing, always push immediately — do not stop at commit"
metadata: 
  type: feedback
  originSessionId: b367eacd-e1d3-4e21-90e1-1727f1685a3e
---

After any commit, push to remote immediately. Do not stop at the commit step and wait for prompting.

**Why:** User had to prompt twice (once to commit, once to push) in the pico-8 session. The work isn't done until it's pushed. A local commit that never reaches remote is as good as nothing from a sync perspective.

**How to apply:**
- `commit-commands:commit-push-pr` skill: use it, and include push in the invocation
- After post-implementation-review triggers a commit, follow immediately with `git push`
- No pause between commit and push — they are one atomic operation from the user's perspective
- Exception: only if on a local-only branch with no remote configured, surface this explicitly rather than failing silently
