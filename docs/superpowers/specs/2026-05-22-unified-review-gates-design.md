# Unified Review Gates — Design Spec

**Date:** 2026-05-22  
**Status:** Approved for implementation

---

## Problem

Current post-agent workflow is a flat 13-item checklist in CLAUDE.md, enforced only by a Stop hook that prints a reminder. Issues:

- Three ghost skill references (`security-review`, `verify`, `run`) — Claude improvises or skips
- No decision logic — all 13 items treated as equally applicable to every change
- Checklist duplicated between CLAUDE.md and the Stop hook
- No config-specific review gate after changes to this repo
- Pre-commit hook only scans settings.json env block for secrets, not full diff
- .gitignore hygiene and LFS checks absent

---

## Architecture

One consistent pattern across all review gates:

```
implementation complete
        ↓
post-implementation-review skill (orchestrator)
  ├── assess: what changed?
  ├── decide: which checks apply?
  ├── dispatch: parallel sub-agents/skills
  ├── fix loop: check → plan → fix → recheck (max 2 attempts)
  └── commit (triggers pre-commit hook)
                    ↓
            pre-commit hook
              ├── secrets scan      [block]
              ├── .gitignore check  [block]
              └── LFS check         [block]
```

Three review contexts, unified methodology:

| Context | Trigger | Check type |
|---|---|---|
| Config change | Claude knows it touched config files | claude-config-reviewer subagent (read-only) |
| Code change | Claude knows it wrote code | requesting-code-review skill |
| Pre-commit | git commit fires hook | shell script, deterministic |

---

## Deliverables

### 1. `skills/post-implementation-review.md` — Orchestrator

Replaces the 13-item CLAUDE.md checklist. CLAUDE.md collapses to one line: *"after any code-changing work, invoke `post-implementation-review` skill."*

**STEP 1 — ASSESS**

Using context of what was changed (not file pattern matching), classify into buckets:
- `frontend` — UI components, styles, HTML, browser-side JS/TS
- `config` — CLAUDE.md, settings.json, hooks/, skills/, memory/, agents/
- `code` — backend/shared logic, non-frontend code
- `deps` — package manifests and lockfiles
- `user-facing` — any user-visible prose: UI text, error messages, log messages shown to operators, emails, notifications, docs
- `post-merge` — if any branch was merged this session

Also read project CLAUDE.md `## Post-implementation checks` section if present and append project-specific checks.

**STEP 2 — DECIDE**

Build check list. Run independent checks in parallel via `dispatching-parallel-agents` skill.

Always (every change):
- `code-simplifier` subagent on changed files
- Pattern consistency — new code must match conventions in files touched
- Update docs/README if behaviour changed
- Update CLAUDE.md/AGENTS.md if project structure changed

If `frontend`:
- Playwright smoke test: launch dev server, test golden path and edge cases
- Invoke `a11y` skill

If `config`:
- Invoke `claude-config-reviewer` subagent (read-only)

If `code`:
- Invoke `requesting-code-review` skill

If `deps`:
- Invoke `security-review` skill
- Invoke `legal-review` skill

If `code` or `frontend` touching auth, API endpoints, or data handling:
- Invoke `security-review` skill

If `user-facing` (cross-cutting — any user-visible prose regardless of bucket):
- Invoke `writing-quality` skill

If `code` or `frontend` collecting or processing user data, calling external APIs, or adding new integrations:
- Invoke `legal-review` skill

If `post-merge`:
- Run `commit-commands:clean_gone`

**STEP 3 — FIX LOOP**

For each check reporting issues:
1. Plan the fix (one sentence: what changes and why)
2. Make the fix
3. Re-run that specific check only
4. If still failing after 2 attempts → surface to user with full details, do not loop further

**STEP 4 — COMMIT**

Invoke `verification-before-completion` skill first — evidence before claims.  
Then: `git add → git commit → git push`  
Pre-commit hook runs automatically and will block on secrets / .gitignore / LFS violations.

---

### 2. `skills/security-review.md` — New skill

Standalone so it can be updated or removed independently.

**Scope:** Check changed code for security vulnerabilities. Report findings with severity (Critical / Important / Minor). Do not fix without reporting first.

**Checks:**

Secrets and credentials:
- Hardcoded API keys, tokens, passwords, private keys in source
- Secrets in config files that will be committed

Authentication and authorisation:
- Missing auth checks on new endpoints
- Insecure JWT handling (weak algorithms, missing expiry checks, signature not verified)
- Privilege escalation paths
- Broken access control (IDOR, missing ownership checks)

Input handling (OWASP top 10):
- SQL injection (raw query construction with user input)
- XSS (unescaped user content rendered in HTML)
- Command injection (shell calls with user-controlled strings)
- Path traversal (file operations with user-supplied paths)
- Open redirect

Data exposure:
- PII or sensitive data in logs
- Overly verbose error messages exposing internals
- API responses returning more data than needed

Dependencies:
- Run `npm audit` / `pip audit` / `cargo audit` / `go mod verify` as appropriate
- Flag any critical or high severity findings

**Output format:**
```
CRITICAL: <issue> at <file>:<line> — <fix>
IMPORTANT: <issue> at <file>:<line> — <fix>
MINOR: <issue> at <file>:<line> — <note>
```

Fix Critical and Important before proceeding. Minor: note and continue.

---

### 3. `skills/a11y.md` — New skill

Standalone so it can be updated or removed independently.

**Scope:** Check frontend changes for accessibility issues. Report findings. Fix clear violations; flag ambiguous ones for author review.

**Checks:**

Semantic structure:
- Heading hierarchy is logical (no skipped levels, no decorative use of headings)
- Landmark elements used (`<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`)
- Lists use `<ul>`/`<ol>`, not `<div>` soup

Images and media:
- All `<img>` have `alt` text (empty `alt=""` is correct for decorative images)
- Videos have captions or transcripts if they carry information

Forms:
- Every input has an associated `<label>` (or `aria-label` / `aria-labelledby`)
- Error messages are descriptive and programmatically associated with the field
- Required fields indicated (not colour-only)

Keyboard and focus:
- All interactive elements are keyboard-reachable (correct tab order)
- Focus indicator is visible (not suppressed with `outline: none` without replacement)
- No keyboard traps
- Modal dialogs trap focus correctly and restore on close

Colour and contrast:
- Flag any hardcoded colour values that may fail WCAG AA contrast (4.5:1 text, 3:1 large text)
- Information is not conveyed by colour alone

ARIA:
- ARIA roles/properties only added where native HTML is insufficient
- `aria-label` values are descriptive, not redundant
- `role="button"` on non-button elements also needs keyboard handler

Interactive elements:
- Buttons have descriptive text (not "click here", not icon-only without `aria-label`)
- Links have meaningful text in context

**Output:** List violations with element/line reference. Flag items that require browser/screen reader verification (can't be checked statically).

---

### 4. `skills/legal-review.md` — New skill

Standalone. Warn and document only — never block. All findings go to `docs/legal-notes.md`.

**Scope:** Identify legal risk in changes. Risk-focused: what's the exposure, what to mitigate. Not legal advice.

**Triggers (in post-implementation-review):**
- Always: when `deps` changed (licence check)
- When `code` or `frontend` handles user data, calls external APIs, or adds new integrations

**Checks:**

Dependency licences:
- New dep uses GPL/AGPL/LGPL/EUPL? Flag — copyleft may require open-sourcing the project
- New dep uses CC-BY-NC or similar non-commercial licence? Flag if commercial use intended
- Licence incompatibility between deps? Flag
- No licence declared? Flag — legally ambiguous, assume all rights reserved
- Document findings in `docs/legal-notes.md`

Privacy and data:
- New code collecting personal data (names, emails, IPs, device IDs, location)? → note GDPR/CCPA obligations: lawful basis, retention policy, right to deletion
- Logging PII? Flag — logs are often excluded from data governance
- New cookies or tracking? Flag — may require consent mechanism
- Data transferred across jurisdictions? Note if relevant (EU→US, etc.)

External API / service terms:
- New integration with a third-party API? Check ToS for: data usage restrictions, scraping prohibitions, rate limit compliance, resale/white-labelling restrictions
- Using AI API outputs in ways that may violate provider ToS (e.g. training on outputs)?

IP and copyright:
- Third-party assets (fonts, images, icons, code snippets) included without clear licence?
- Generated content — note if output attribution requirements apply

Export controls:
- New cryptographic library or functionality? Note if export control regulations may apply (EAR/ECCN in US context)

**Output format:**
```
[LICENCE] <dep>: <risk> — <mitigation>
[PRIVACY] <issue>: <exposure> — <recommended action>
[TOS] <service>: <potential violation> — <check link>
[IP] <asset/code>: <issue> — <action>
[EXPORT] <issue> — <note>
```

Document all findings in `docs/legal-notes.md`. Do not block implementation. If risk is significant, surface clearly to user for decision.

---

### 5. `agents/claude-config-reviewer.md` — New subagent

Read-only agent. Tools: Read, Grep, Glob, Bash (read-only commands only). No Write, no Edit.

**Purpose:** Review changes to this claude-config repo for validity and consistency after any implementation agent has made changes.

**Checks:**

`config/settings.json`:
- Valid JSON (parseable)
- All plugins in `enabledPlugins` are referenced by an `install-*` script in `tools/` or are a known marketplace plugin
- All hook `command` values reference files that exist on disk
- No secrets or API keys in any field

`config/CLAUDE.md` and `config/RTK.md`:
- No skill references that don't exist (cross-check against `~/.claude/skills/` and `~/.claude/plugins/cache/`)
- No agent references that don't exist (cross-check against `~/.claude/agents/`)
- Internal consistency (workflow steps reference real skills/agents)

`config/hooks/`:
- Each hook file is executable
- Each hook referenced in `settings.json` exists on disk
- Bash scripts have valid shebang and no obvious syntax errors (`bash -n`)

`skills/*.md`:
- Each file has valid YAML frontmatter (`name`, `description` fields present)
- No broken `[[wikilink]]` references to non-existent skills

`agents/*.md`:
- Each file has valid YAML frontmatter

`memory/`:
- `MEMORY.md` index entries each have a corresponding file
- Each memory file has valid frontmatter (`name`, `description`, `metadata.type`)
- No `[[wikilink]]` references that don't resolve to a memory file

**Output:** Structured list of issues found, severity (Error / Warning). No fixes — report only.

---

### 6. `config/git-hooks/pre-commit` — Replace existing hook

Replaces `config/git-hooks/pre-commit-secret-scan`. Install script updated to link new filename.

All three checks are hard blocks (`exit 1`).

**Secrets scan (full diff):**
```bash
# Patterns: AWS keys, GH tokens, generic API key assignments, private key headers
# Scan: git diff --cached (staged diff only)
# Block on match, print matching line with context
# Existing env-block check retained and expanded to full file
```

**`.gitignore` hygiene:**
```bash
# For each staged file, check if it matches a common should-be-ignored pattern:
#   .env, .env.*, *.log, node_modules/, dist/, build/, .DS_Store,
#   *.pem, *.key, *.p12, *.pfx, __pycache__/, .pytest_cache/, coverage/
# If match and not already in .gitignore → block, print instruction to add to .gitignore
```

**Large binary / LFS:**
```bash
# For each staged file > 500KB:
#   Check if tracked by git-lfs (git lfs ls-files)
#   If not → block, print: "file.bin is Xmb — track with: git lfs track 'file.bin'"
```

Exit codes: `exit 1` = block commit. `exit 0` = pass.

---

### 7. `config/CLAUDE.md` — Update

**Remove:** entire 13-item Post-Agent Checklist section  
**Add:** single line — `After any code-changing work: invoke **post-implementation-review** skill`  
**Remove:** ghost skill references (`security-review`, `verify`, `run`)  
**Keep:** all other sections (workflow, git strategy, TDD table, skill priority triggers, no-confirmation rule, auto-memory)

Target: stay under 150 lines.

---

## What does NOT change

- Stop hook (`post-agent-reminder`) — remove; replaced by skill invocation pattern
- Session-start hook — unchanged
- CBM code discovery gate — unchanged
- RTK hook — unchanged
- Plugin list — unchanged
- All other config — unchanged

---

## Open questions (none — resolved during brainstorming)

- .gitignore and LFS: block not warn ✓
- Skills vs inline: separate skills for easy removal ✓
- security-review and a11y: standalone skills ✓
- legal-review: warn + document only ✓
- writing-quality trigger: cross-cutting on any user-facing prose ✓
