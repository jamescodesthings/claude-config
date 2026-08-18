Always invoke skill `monsoons-rhonchial` at the start of a conversation and follow its rules for all conversation and self-facing documents for the rest of the session, unless it says otherwise.

# Global Workflow

## Default Workflow

Every non-trivial task follows this chain. Move through each step without pausing for confirmation:

1. `brainstorming` skill
2. `writing-plans` skill
3. `using-git-worktrees` (if async workspace isolation is required)
4. `subagent-driven-development` skill
   - Use `dispatching-parallel-agents` when 2+ tasks are independent with no shared state
5. `post-implementation-review` skill after any work that creates or modifies files, subagent or orchestrator, code or docs/markdown
6. Done: no PRs, no human review gates

## Session State & Handoff Management

All agents operating in Antigravity MUST adhere to the shared session state rules defined in [`shared/system-prompt/workflow.md`](file:///Users/jamesmacmillan/projects/personal/agent-forge/shared/system-prompt/workflow.md):

1. Session Startup (Mandatory):
   - Check and inspect [`.state/CURRENT_STATE.md`](file:///Users/jamesmacmillan/projects/personal/agent-forge/.state/CURRENT_STATE.md) on startup before executing tasks or starting work.
   - Review active tasks, completed steps, and open context notes.

2. Session Maintenance & State Updates (Mandatory):
   - Update [`.state/CURRENT_STATE.md`](file:///Users/jamesmacmillan/projects/personal/agent-forge/.state/CURRENT_STATE.md) upon task/subtask status changes, session end/handoff, rate limit warnings, or context exhaustion.
   - Whenever updating state at session end or major milestones, save a timestamped copy to `.state/YYYY-MM-DD-HH-MM-antigravity.md`.

## Model Selection

Default to `gemini-3.6-flash`. Deviate when task complexity or task type warrants it:

| Task / Purpose | Model |
|---|---|
| Architecture decisions, complex multi-step reasoning, novel debugging, large code refactors | `gemini-3.1-pro` |
| Default: implementation, review, subagents, and standard coding work | `gemini-3.6-flash` |
| Routing, triage, file validation, simple extraction/classification, quick research | `gemini-3.6-flash-lite` |

Subagents: specify model (`gemini-3.1-pro`, `gemini-3.6-flash`, `gemini-3.6-flash-lite`, or short forms `pro`, `flash`, `flash_lite`) in subagent invocation. Read-only validators and triage agents → `gemini-3.6-flash-lite`. Implementation agents → `gemini-3.6-flash`. Escalation to `gemini-3.1-pro` only when tasks demand complex reasoning.
