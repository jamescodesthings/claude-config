---
name: feedback_post_impl_trigger
description: "post-implementation-review must fire for all file writes, not just \"code-changing agents\""
metadata: 
  node_type: memory
  type: feedback
  originSessionId: afcb11e4-3758-478f-a6fd-d7e162393210
---

Always invoke `post-implementation-review` after any work that creates or modifies files — regardless of whether a subagent or orchestrator did the work, and regardless of whether the files are code or docs/markdown.

**Why:** "code-changing agent" wording excluded orchestrator inline writes and non-code repos (planning/docs), causing commits to be silently skipped. Discovered via financial-plan repo where plans and tasks were completed but never committed.

**How to apply:** Treat the trigger as file-write-based, not agent-type or file-type based. Also: orchestrator must always delegate file writes to subagents (never write inline), so the trigger fires consistently. See [[feedback_subagent_preference]].
