---
name: post-implementation-review
description: Post-code checks — run after any file writes, then commits
---

# Post-Implementation Review

Replaces the post-agent checklist. Run after any code-changing work.

## STEP 1 — ASSESS

Using your knowledge of what you just changed (not file pattern matching), classify changes into buckets. A single change can fall into multiple buckets.

| Bucket | What qualifies |
|---|---|
| `frontend` | UI components, styles, HTML, browser-side JS/TS/CSS, templates |
| `config` | CLAUDE.md, settings.json, hooks/, skills/, memory/, agents/ in this config repo |
| `code` | Backend/shared logic, scripts, non-frontend code |
| `deps` | package.json, package-lock.json, go.mod, go.sum, Cargo.toml, Cargo.lock, pyproject.toml, requirements.txt, Pipfile |
| `user-facing` | Any user-visible prose: UI labels/copy, error messages, log messages shown to operators, emails, notifications, docs, READMEs |
| `post-merge` | A branch was merged this session |

Also read the project's CLAUDE.md for a `## Post-implementation checks` section and append any project-specific checks to your list.

## STEP 2 — DECIDE AND DISPATCH

Build your check list from the buckets. Run independent checks in parallel using the `dispatching-parallel-agents` skill where possible.

**Always (every change):**
- Dispatch `code-simplifier` agent on changed files
- Check pattern consistency — new code must match conventions in files it was added to
- Update docs/README if observable behaviour changed
- Update project CLAUDE.md/AGENTS.md if project structure or conventions changed

**If `frontend`:**
- Launch dev server and run Playwright smoke tests: test golden path + at least two edge cases
- Invoke `a11y` skill on changed components

**If `config`:**
- Dispatch `claude-config-reviewer` agent (read-only)

**If `code`:**
- Invoke `requesting-code-review` skill

**If `code` or `frontend` touching auth, API endpoints, or data handling:**
- Invoke `security-code-review` skill

**If `deps`:**
- Invoke `security-code-review` skill (run dep audit)
- Invoke `legal-review` skill (licence check)

**If `user-facing` (cross-cutting — applies regardless of other buckets):**
- Invoke `writing-quality` skill on all changed user-visible prose

**If `code` or `frontend` collecting/processing user data, calling external APIs, or adding new integrations:**
- Invoke `legal-review` skill

**If `post-merge`:**
- Run `commit-commands:clean_gone`

## STEP 3 — FIX LOOP

For each check that reports issues:

1. Plan the fix in one sentence (what changes and why)
2. Make the fix
3. Re-run that specific check only
4. If still failing after 2 attempts → surface to user with full details, do not loop further

## STEP 4 — COMMIT

Invoke `verification-before-completion` skill — evidence before claims.

Then:
```bash
git add <changed files>
git commit -m "<imperative subject>"
git push
```

The pre-commit hook runs automatically and will hard-block on secrets, .gitignore violations, and untracked large binaries. Fix those before retrying the commit.
