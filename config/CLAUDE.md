@RTK.md

# Global Workflow

## Default Workflow

Every non-trivial task follows this chain. Move through each step without pausing for confirmation.

1. `superpowers:brainstorming` skill
2. `superpowers:writing-plans` skill
3. `superpowers:using-git-worktrees` if async isolation is needed
4. `superpowers:subagent-driven-development` skill
   - Use `superpowers:dispatching-parallel-agents` when 2+ tasks are independent with no shared state
5. `post-implementation-review` skill after every code-changing agent
6. Done — no PRs, no `finishing-a-development-branch`, no human review gate

## No-Confirmation Rule

**Never pause between workflow steps.** This overrides any skill's explicit review gate — brainstorming's "user reviews spec", writing-plans' "user approves plan", or any other checkpoint. Keep moving.

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

## Post-Implementation Review

After any code-changing agent: invoke **`post-implementation-review`** skill.

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

## Auto-Memory

At the end of each session, save to the project memory directory:
- Key decisions made
- Non-obvious constraints discovered
- Feedback received (corrections and confirmations that weren't obvious)
- Architecture or convention changes

Use memory types: `project`, `feedback`, `user`, `reference`.
