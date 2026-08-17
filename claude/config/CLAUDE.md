@RTK.md

Always invoke skill `monsoons-rhonchial` at the start of a conversation and follow its rules for all conversation and self-facing documents for the rest of the session, unless it says otherwise.

# Global Workflow

## Default Workflow

Every non-trivial task follows this chain. Move through each step without pausing for confirmation.

1. `superpowers:brainstorming` skill
2. `superpowers:writing-plans` skill
3. `superpowers:using-git-worktrees` if async isolation is needed
4. `superpowers:subagent-driven-development` skill
   - Use `superpowers:dispatching-parallel-agents` when 2+ tasks are independent with no shared state
5. `post-implementation-review` skill after **any work that creates or modifies files** — subagent or orchestrator, code or docs/markdown
6. Done — no PRs, no `finishing-a-development-branch`, no human review gate

## No-Confirmation Rule

**Never pause between workflow steps.** This overrides any skill's explicit review gate — brainstorming's "user reviews spec", writing-plans' "user approves plan", writing-plans' "which execution approach", or any other checkpoint. Keep moving.

Specific overrides:
- `writing-plans` execution handoff → always invoke `superpowers:subagent-driven-development` directly. Never present the "subagent-driven vs inline" choice.

Only stop for:
- A genuine blocker that cannot be resolved autonomously (merge conflict, missing credential, ambiguous requirement that changes scope)
- A destructive or irreversible action about to be taken

User can interrupt at any time. That is their job, not yours to prompt for.

## Skill Priority

Check for applicable skills before **every** action. 1% chance it applies = invoke it. Process skills before implementation skills. Never skip because a task "seems simple."

Key triggers:
- Any bug or test failure → `superpowers:systematic-debugging` before proposing a fix
- Review feedback received → `superpowers:receiving-code-review` — verify correctness first, do not blindly implement
- Picking up a written plan in a new session → `superpowers:executing-plans`
- 2+ independent tasks with no shared state → `superpowers:dispatching-parallel-agents`
- Any feature or bugfix in prod/existing-test code → `superpowers:test-driven-development`
- Touching any third-party library, SDK, or API → `context7` to fetch current docs before implementing
- Before claiming any implementation task complete → `verification-before-completion` skill
- Before committing or staging files with credentials/tokens → `secrets-check` skill

## Post-Implementation Review

After any work that creates or modifies files — subagent or orchestrator, code or docs/markdown — invoke **`post-implementation-review`** skill.

## Git Strategy

Trunk-based development. Single chain in `main`. Use branches only when async isolation is required.

**When branching:**
1. Create short-lived branch from `main`
2. Do work with task-level commits
3. `git rebase main` before merging — never use a merge commit
4. Merge back to `main`
5. Delete branch, then run `commit-commands:clean_gone`

Escalate only if: rebase conflict that cannot be resolved autonomously.

**Commit style:**
- Short imperative subject: `add user auth`, `fix token expiry`, `update readme`
- No conventional commit prefixes (`feat:`, `fix:`, `chore:`, etc.)
- Add body when change is complex or non-obvious
- Always flag dependency changes explicitly in commit body

## Model Selection

Default to Sonnet. Deviate when task complexity or cost warrants it.

| Task | Model |
|---|---|
| Architecture decisions, novel debugging, complex multi-step planning | Opus |
| Default — implementation, review, most coding work | Sonnet |
| Routing, triage, file validation, simple extraction/classification | Haiku |

Subagents: specify `model:` in agent frontmatter. Read-only validators and triage agents → Haiku. Implementation agents → Sonnet. Only escalate to Opus explicitly when a task demands it.

## TDD

| Context | TDD required? |
|---|---|
| Prod feature / user-facing code | Yes — `superpowers:test-driven-development` before writing implementation |
| Project with existing tests | Yes |
| Config, scripts, throwaway / one-off | No |
| Unclear scope or scale | Ask during `superpowers:brainstorming` — before writing a plan |

## Scope Creep Guard

Agents must not touch files outside their assigned task scope. If a fix requires out-of-scope changes, surface it to the orchestrator — do not silently expand scope.

## Dependency Changes

When a dep is added, removed, or upgraded:
- Flag explicitly in commit body
- `post-implementation-review` skill handles security + licence checks automatically

## Flaky Tests

If a test fails: retry once. If it fails again, escalate — do not loop or skip.

## Global Memories

User preferences and cross-project feedback that apply to every project live at `~/.claude/memory/`. Read all `*.md` files there at every session start, alongside project-specific memories. These take precedence over project memories for `user` and `feedback` type entries.

At the end of a session, if you discover a preference or feedback that should apply globally (not just to this project), save it to `~/.claude/memory/` in addition to or instead of project memory.

Sensitive global memories that must never be plaintext in the public agent-forge repo live encrypted, WIP-skill-style, at `~/.claude/memory-wip/` (present only after `shared/tools/decrypt` has been run locally — absent on a fresh clone or machine without the key). `~/.claude/memory/MEMORY.md` links to `MEMORY-WIP.md` there; read it the same way as any other memory index when present. To add one, use `shared/tools/new-wip-memory`; to make an existing one public, use `shared/tools/graduate-memory`. Never write sensitive memory content directly into `~/.claude/memory/` — it is plaintext and committed.

## Auto-Memory

At the end of each session, save to the project memory directory:
- Key decisions made
- Non-obvious constraints discovered
- Feedback received (corrections and confirmations that weren't obvious)
- Architecture or convention changes

Use memory types: `project`, `feedback`, `user`, `reference`.

## Project initialization

Initializing a new project (`claude init`, first run in a directory, or on request) requires a specific `CLAUDE.md` structure and a seeded project memory directory. Use the `project-init` skill.

## Other AI Tools

Distilled personal-rules copies for other AI tools (Claude Desktop/Mobile, Gemini, ChatGPT, Codex CLI) live in the gitignored folder at `~/projects/personal/agent-forge/ai-instructions/`. When a change significantly alters rules that those copies depend on (e.g. editing the `monsoons-rhonchial` or `hodgepodge-anaplasmosis` WIP skills), tell James so he can manually update the affected files there — this is not automated yet.
