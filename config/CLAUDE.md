@RTK.md

# Global Workflow

## Default Workflow

Every non-trivial task follows this chain. Move through each step without pausing for confirmation unless a genuine blocker exists (missing credential, unresolvable conflict, scope ambiguity that changes the task).

1. `superpowers:brainstorming` skill
2. `superpowers:writing-plans` skill
3. User reviews plan — **only human touchpoint before implementation starts**
4. `superpowers:using-git-worktrees` if async isolation is needed
5. `superpowers:subagent-driven-development` skill
   - Use `superpowers:dispatching-parallel-agents` when 2+ tasks are independent with no shared state
6. Post-agent checklist (see § Post-Agent Checklist) after every code-changing agent
7. Done — no PRs, no `finishing-a-development-branch`, no human review gate

## Skill Priority

Check for applicable skills before **every** action. 1% chance it applies = invoke it. Process skills before implementation skills. Never skip because a task "seems simple."

Key triggers:
- Any bug or test failure → `superpowers:systematic-debugging` before proposing a fix
- Review feedback received → `superpowers:receiving-code-review` — verify correctness first, do not blindly implement
- Picking up a written plan in a new session → `superpowers:executing-plans`
- 2+ independent tasks with no shared state → `superpowers:dispatching-parallel-agents`
- Any feature or bugfix in prod/existing-test code → `superpowers:test-driven-development`

## No-Confirmation Rule

Do **not** pause between workflow steps to ask "should I continue?", "shall I proceed?", or "does this look right?" when there is no blocker.

Keep moving unless:
- A genuine blocker that cannot be resolved autonomously (merge conflict, missing credential, ambiguous requirement that changes scope)
- A destructive or irreversible action is about to be taken

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

## Post-Agent Checklist

Run after every agent that changes code. No confirmation between steps.

1. **`superpowers:requesting-code-review`** — always
2. **`code-simplifier` skill** on changed files — always
3. **Pattern consistency** — new code must match existing conventions in files touched
4. **Update docs/README** — if behaviour changed
5. **Update project CLAUDE.md / AGENTS.md** — if structure or conventions changed
6. **`security-review` skill** — if auth, API endpoints, data handling, or deps changed
7. **Legal risk check** — if new deps, licences, or data handling involved: warn + document in `docs/legal-notes.md`, do **not** block
8. **a11y check** — if frontend changed
9. **`writing-quality` skill** — if user-facing content changed (UI copy, log messages, emails, docs)
10. **`verify` skill + `run` skill + Playwright** — if frontend changed
11. **Lint + type-check + test suite** — if project has them; retry flaky tests once before escalating
12. **`commit-commands:clean_gone`** — after any branch merge
13. **`git add` → `git commit` → `git push`** — always, after all above pass

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
- Always trigger `security-review`
- Check licence — document any non-permissive licence in `docs/legal-notes.md`

## Flaky Tests

If a test fails: retry once. If it fails again, escalate — do not loop or skip.

## Auto-Memory

At the end of each session, save to the project memory directory:
- Key decisions made
- Non-obvious constraints discovered
- Feedback received (corrections and confirmations that weren't obvious)
- Architecture or convention changes

Use memory types: `project`, `feedback`, `user`, `reference`.
