# Global Agent Workflow & Session State Rules

This document defines the mandatory workflow rules and session state tracking protocol for all AI agents across tools (Claude Code, Antigravity CLI, Codex CLI, Copilot CLI).

## 1. Session Startup (Mandatory)
- Check state first: on session startup, every agent MUST inspect `.state/CURRENT_STATE.md` before executing any commands or starting work.
- Context synchronization: review active tasks, completed steps, and open issues noted in the current state handoff document.

## 2. Session Maintenance & State Updates (Mandatory)
- Update triggers: every agent MUST update `.state/CURRENT_STATE.md` under any of the following conditions:
  - Task completion or subtask status changes.
  - End of session / agent handoff.
  - Rate limit warnings, context exhaustion, or session interruption.
- Snapshot creation: whenever updating session state at session end or major milestones, save a timestamped copy to `.state/YYYY-MM-DD-HH-MM-<tool>.md` (e.g. `.state/2026-08-09-14-25-antigravity.md` or `.state/2026-08-09-14-25-claude.md`).

## 3. Task State Tracking Format
- Checkbox lists: maintain active project tasks using concise markdown checkbox lists with standard status symbols:
  - `- [ ]` Pending / Not started
  - `- [/]` In progress
  - `- [x]` Completed
  - `- [-]` Skipped / Cancelled
- Clear headings: group tasks by phase or milestone, including metadata headers for:
  - Active Tool (e.g., `claude`, `antigravity`, `codex`, `copilot`)
  - Date & Time Stamp (ISO-8601 or standard local timestamp format)
  - Current Active Task Status

## 4. State Handoff Protocol
1. Prepare state: ensure all completed work is reflected in `.state/CURRENT_STATE.md`.
2. Archive snapshot: write the snapshot file `.state/YYYY-MM-DD-HH-MM-<tool>.md`.
3. Commit state (if appropriate): stage and commit state updates when completing phases or significant milestones.
