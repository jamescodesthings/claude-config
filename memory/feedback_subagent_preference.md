---
name: feedback_subagent_preference
description: User always prefers subagent-driven development over inline execution when given a choice
metadata: 
  node_type: memory
  type: feedback
  originSessionId: da81ef1d-a71c-417d-9967-2927b95396b9
---

Always use subagent-driven development (superpowers:subagent-driven-development) when executing plans. Never choose inline execution.

**Why:** User stated "prefer subagent always" when given execution options.

**How to apply:** Whenever writing-plans skill offers execution choice, automatically go with subagent-driven without asking.
