# Unified Review Gates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat 13-item post-agent checklist and ghost skill refs with a unified, modular review gate system.

**Architecture:** Seven new/modified files — four standalone skills, one read-only config-reviewer subagent, one enhanced pre-commit hook, one settings.json cleanup. Tasks 1–6 are fully independent and can be dispatched in parallel. Task 7 must run after Task 6 (modifies same settings.json area). Task 8 is independent.

**Tech Stack:** Markdown (skills/agents), Bash (pre-commit hook)

**Spec:** `docs/superpowers/specs/2026-05-22-unified-review-gates-design.md`

---

### Task 1: `skills/security-review.md`

**Files:**
- Create: `skills/security-review.md`

No tests — skill file. Verify: frontmatter is valid YAML, file is readable.

- [ ] **Step 1: Write the skill file**

```markdown
---
name: security-review
description: Use when code, auth, API endpoints, data handling, or dependencies changed — checks for OWASP top 10, secrets, auth issues, and vulnerable deps
---

# Security Review

Check changed code for security vulnerabilities. Report findings with severity. Do not fix without reporting first.

## Output Format

```
CRITICAL: <issue> at <file>:<line> — <fix>
IMPORTANT: <issue> at <file>:<line> — <fix>
MINOR: <issue> at <file>:<line> — <note>
```

Fix Critical and Important before proceeding. Minor: note and continue.

## Checks

### Secrets and credentials
- Hardcoded API keys, tokens, passwords, private keys in source
- Secrets in config files staged for commit
- Environment variables with real values committed (not just names)

### Authentication and authorisation
- New endpoints missing auth checks
- JWT: weak algorithms (none/HS256 with shared secret), missing expiry, signature not verified
- Privilege escalation paths — can a lower-privilege caller reach a higher-privilege operation?
- Broken access control: IDOR (using user-supplied IDs without ownership check), missing authorisation on resource operations

### Input handling (OWASP top 10)
- SQL injection: raw query construction using user input (string concat, f-strings, sprintf into queries)
- XSS: user-controlled content rendered into HTML without escaping
- Command injection: shell calls (`exec`, `subprocess`, `child_process`) with user-controlled strings
- Path traversal: file operations with user-supplied paths lacking sanitisation
- Open redirect: redirects to user-supplied URLs without allowlist

### Data exposure
- PII or sensitive data written to logs
- Overly verbose error messages exposing stack traces, internal paths, or schema details to callers
- API responses returning more fields than the caller needs (over-fetching with sensitive fields)

### Dependencies
Run the appropriate audit command for the project's ecosystem:
- Node: `npm audit --audit-level=high`
- Python: `pip-audit` or `safety check`
- Rust: `cargo audit`
- Go: `go mod verify` + `govulncheck ./...`

Flag any critical or high severity findings. Do not proceed past CRITICAL dep vulnerabilities.
```

- [ ] **Step 2: Verify**

```bash
head -5 skills/security-review.md
```
Expected: YAML frontmatter with `name: security-review`

- [ ] **Step 3: Commit**

```bash
git add skills/security-review.md
git commit -m "add security-review skill"
```

---

### Task 2: `skills/a11y.md`

**Files:**
- Create: `skills/a11y.md`

- [ ] **Step 1: Write the skill file**

```markdown
---
name: a11y
description: Use when frontend code changed — checks semantic HTML, ARIA, keyboard navigation, contrast, forms, and images for accessibility violations
---

# Accessibility Review (a11y)

Check frontend changes for accessibility issues. Fix clear violations in place. Flag ambiguous items for author review rather than guessing intent.

## Output Format

List violations with element and file:line reference. Mark items requiring browser/screen-reader verification with `[manual check]`.

## Checks

### Semantic structure
- Heading hierarchy is logical — no skipped levels (h1 → h3), no headings used for visual styling
- Landmark elements present: `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>` where appropriate
- Lists use `<ul>`/`<ol>` — not `<div>` or `<span>` chains masquerading as lists

### Images and media
- All `<img>` have `alt` attribute — empty `alt=""` is correct for purely decorative images, not missing
- Icons used as interactive elements have `aria-label` or adjacent visible text
- Videos carrying information have captions or transcripts

### Forms
- Every `<input>`, `<select>`, `<textarea>` has an associated `<label>` via `for`/`id`, `aria-label`, or `aria-labelledby`
- Error messages are descriptive ("Email must be a valid address", not "Invalid input") and programmatically associated with their field via `aria-describedby`
- Required fields indicated in a way that doesn't rely solely on colour
- Submit buttons have descriptive text

### Keyboard and focus
- All interactive elements reachable by Tab in logical order
- Focus indicator visible — `outline: none` / `outline: 0` without a replacement style is a violation
- No keyboard traps — user can Tab out of every component
- Modal dialogs: focus moves into modal on open, is trapped within, restores to trigger on close

### Colour and contrast
- Hardcoded colour values that may fail WCAG AA (4.5:1 for normal text, 3:1 for large text/UI components) — flag for `[manual check]` if cannot verify statically
- Information not conveyed by colour alone (error states use icon + text, not just red colour)

### ARIA
- ARIA roles/properties only added where native HTML semantics are insufficient
- `aria-label` values are descriptive and not redundant with visible text
- `role="button"` on a non-`<button>` element also has `tabindex="0"` and keyboard handler
- `aria-hidden="true"` not applied to focusable elements

### Interactive elements
- Buttons have descriptive accessible text — not "click here", not icon-only without `aria-label`
- Links describe their destination in context — not "read more" without context
```

- [ ] **Step 2: Verify**

```bash
head -5 skills/a11y.md
```
Expected: YAML frontmatter with `name: a11y`

- [ ] **Step 3: Commit**

```bash
git add skills/a11y.md
git commit -m "add a11y skill"
```

---

### Task 3: `skills/legal-review.md`

**Files:**
- Create: `skills/legal-review.md`

- [ ] **Step 1: Write the skill file**

```markdown
---
name: legal-review
description: Use when dependencies changed or code handles user data, calls external APIs, or adds new integrations — warn and document only, never block
---

# Legal Review

Identify legal risk in changes. Risk-focused: what is the exposure, what to mitigate. Not legal advice. Never block implementation — warn and document all findings in `docs/legal-notes.md`.

## Output Format

```
[LICENCE] <dep>: <risk> — <mitigation>
[PRIVACY] <issue>: <exposure> — <recommended action>
[TOS] <service>: <potential violation> — <what to check>
[IP] <asset/code>: <issue> — <action>
[EXPORT] <issue> — <note>
```

All findings go to `docs/legal-notes.md`. If risk is significant, surface clearly to user for decision before proceeding.

## Checks

### Dependency licences
Inspect new or changed dependencies:
- **GPL/AGPL/LGPL/EUPL**: Copyleft — may require open-sourcing the consuming project. Flag if project is closed-source or commercial.
- **GPL v2 vs v3**: incompatible with each other and many permissive licences — flag if mixing.
- **CC-BY-NC / non-commercial**: flag if project has commercial use.
- **No licence declared**: legally "all rights reserved" by default — flag as ambiguous, do not assume permissive.
- **Licence incompatibility**: two deps with incompatible licences in the same binary — flag.
- **Permissive (MIT, Apache-2.0, BSD, ISC)**: generally safe, note attribution requirements where relevant.

Document in `docs/legal-notes.md` under `## Dependency Licences`.

### Privacy and data handling
- New code collecting personal data (names, emails, IPs, device fingerprints, location, behavioural data) → note applicable regulations: GDPR (EU users), CCPA (California users). Flag: lawful basis required, retention policy needed, right to deletion must be supportable.
- PII written to logs → flag. Logs are frequently excluded from data governance processes and retention policies.
- New cookies or client-side tracking → may require consent mechanism under GDPR/ePrivacy. Flag.
- Data transferred between jurisdictions (EU → US, etc.) → note if relevant; Standard Contractual Clauses or equivalent may be needed.

### External API / service terms of service
- New integration with third-party API → check ToS for:
  - Data usage restrictions (can you store/process their data?)
  - Scraping or bulk access prohibitions
  - Rate limit compliance obligations
  - Resale, white-labelling, or sub-licensing restrictions
  - Attribution requirements
- Using AI API outputs → check provider ToS on: training on outputs, showing outputs to competitors, storing outputs.

### IP and copyright
- Third-party assets included (fonts, images, icons, audio, video, code snippets) → verify licence allows intended use. Flag anything without explicit licence.
- Generated content (AI-generated images, text, code) → note if output attribution or ownership requirements apply under provider ToS.
- Copy-pasted code from Stack Overflow, blogs, etc. → note CC-BY-SA licence on SO requires attribution; assess if licence is compatible.

### Export controls
- New cryptographic library or functionality → note potential applicability of export control regulations (EAR/ECCN in US, similar in other jurisdictions). Strong crypto may require classification and notification.
- Sanctions screening: if product could be used in embargoed countries, flag for review.
```

- [ ] **Step 2: Verify**

```bash
head -5 skills/legal-review.md
```
Expected: YAML frontmatter with `name: legal-review`

- [ ] **Step 3: Commit**

```bash
git add skills/legal-review.md
git commit -m "add legal-review skill"
```

---

### Task 4: `skills/post-implementation-review.md`

**Files:**
- Create: `skills/post-implementation-review.md`

This is the orchestrator. References `security-review`, `a11y`, `legal-review`, `writing-quality`, `requesting-code-review`, `claude-config-reviewer` (agent), `code-simplifier` (agent), `verification-before-completion`, `dispatching-parallel-agents`, `commit-commands:clean_gone`.

- [ ] **Step 1: Write the skill file**

```markdown
---
name: post-implementation-review
description: Use after any code-changing work — assesses what changed, dispatches appropriate checks in parallel, runs fix loop, then commits
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
- Invoke `security-review` skill

**If `deps`:**
- Invoke `security-review` skill (run dep audit)
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
```

- [ ] **Step 2: Verify**

```bash
head -5 skills/post-implementation-review.md
```
Expected: YAML frontmatter with `name: post-implementation-review`

- [ ] **Step 3: Commit**

```bash
git add skills/post-implementation-review.md
git commit -m "add post-implementation-review orchestrator skill"
```

---

### Task 5: `agents/claude-config-reviewer.md`

**Files:**
- Create: `agents/claude-config-reviewer.md`

- [ ] **Step 1: Write the agent file**

```markdown
---
name: claude-config-reviewer
description: Read-only validator for claude-config repo changes. Dispatched by post-implementation-review when config/, skills/, memory/, or agents/ files changed. Reports issues without fixing anything.
---

You are a read-only config validator for a Claude Code configuration repository. You check for validity and consistency issues after changes. You report problems — you never fix them. Do not use Write or Edit tools under any circumstances.

## Your task

Review the current state of the config repository at the path given to you. Check each area below and produce a structured report.

## Checks

### config/settings.json
- Parse as JSON — if invalid, report immediately and stop
- For each `hooks[*][*].command` value: check the referenced file exists on disk
- Check no secrets or API keys appear in any string value (patterns: `sk-`, `AKIA`, `ghp_`, `AIza`, `password`, `api_key`, `api-key`)

### config/CLAUDE.md and any *.md in config/
- For each skill reference of the form `skill-name` or `plugin:skill-name`: verify it exists in `~/.claude/skills/` or `~/.claude/plugins/cache/`
- For each agent reference: verify corresponding file exists in `~/.claude/agents/`
- Flag any reference that cannot be resolved

### config/hooks/
- For each file: check it is executable (`test -x`)
- For each file ending in `.sh` or with a bash shebang: run `bash -n <file>` and report any syntax errors
- Cross-reference with `settings.json` hooks — flag any hook listed in settings but missing from disk

### skills/*.md
- Each file must have YAML frontmatter with `name` and `description` fields
- Flag files missing either field

### agents/*.md
- Each file must have YAML frontmatter with `name` and `description` fields
- Flag files missing either field

### memory/
- Parse `MEMORY.md` — for each `[Title](file.md)` link, verify `file.md` exists in `memory/`
- For each `memory/*.md` (except MEMORY.md): verify frontmatter has `name`, `description`, and `metadata.type` fields
- Valid `metadata.type` values: `user`, `feedback`, `project`, `reference`

## Output format

```
ERROR: <area> — <issue> — <file>:<line if known>
WARNING: <area> — <issue> — <file>:<line if known>
OK: <area> — all checks passed
```

Report every issue found. End with a one-line summary: `N errors, M warnings`.
```

- [ ] **Step 2: Verify**

```bash
head -5 agents/claude-config-reviewer.md
```
Expected: YAML frontmatter with `name: claude-config-reviewer`

- [ ] **Step 3: Commit**

```bash
git add agents/claude-config-reviewer.md
git commit -m "add claude-config-reviewer read-only agent"
```

---

### Task 6: Enhanced pre-commit hook

**Files:**
- Create: `config/git-hooks/pre-commit` (new name — replaces `pre-commit-secret-scan`)
- Modify: `install` (update `install_git_hook` function to reference new filename)
- Delete: `config/git-hooks/pre-commit-secret-scan`

All three checks are hard blocks (`exit 1`).

- [ ] **Step 1: Write the new pre-commit hook**

```bash
#!/usr/bin/env bash
# Pre-commit hook: blocks secrets, .gitignore violations, and untracked large binaries.
set -euo pipefail

RED='\033[0;31m'
NC='\033[0m'
FAILED=0

STAGED_DIFF=$(git diff --cached --unified=0 2>/dev/null || true)
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)

# ── 1. Secrets scan ───────────────────────────────────────────────────────────
declare -a PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'sk-[a-zA-Z0-9]{32,}'
  'ghp_[a-zA-Z0-9]{36}'
  'ghs_[a-zA-Z0-9]{36}'
  'xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+'
  'xoxp-[0-9]+-[0-9]+-[0-9]+-[a-zA-Z0-9]+'
  'AIza[0-9A-Za-z_-]{35}'
  'ya29\.[0-9A-Za-z_-]+'
  '-----BEGIN (RSA|EC|DSA|OPENSSH) PRIVATE KEY'
  'password\s*[:=]\s*["'"'"'][^"'"'"']{6,}'
  'api[_-]?key\s*[:=]\s*["'"'"'][^"'"'"']{8,}'
  'secret\s*[:=]\s*["'"'"'][^"'"'"']{8,}'
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$STAGED_DIFF" | grep -qP "^\+.*${pattern}" 2>/dev/null; then
    echo -e "${RED}[SECRETS]${NC} Potential secret detected — pattern: ${pattern}"
    echo "$STAGED_DIFF" | grep -P "^\+.*${pattern}" | head -3
    FAILED=1
  fi
done

# ── 2. .gitignore hygiene ────────────────────────────────────────────────────
declare -a IGNORE_PATTERNS=(
  '(^|/)\.env(\.|$)'
  '\.log$'
  '(^|/)node_modules/'
  '(^|/)dist/'
  '(^|/)build/'
  '\.DS_Store$'
  '\.pem$'
  '\.key$'
  '\.p12$'
  '\.pfx$'
  '(^|/)__pycache__/'
  '(^|/)\.pytest_cache/'
  '(^|/)coverage/'
  '(^|/)\.nyc_output/'
)

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  for pattern in "${IGNORE_PATTERNS[@]}"; do
    if echo "$file" | grep -qP "$pattern"; then
      if ! git check-ignore -q "$file" 2>/dev/null; then
        echo -e "${RED}[GITIGNORE]${NC} '$file' should be in .gitignore (matches: ${pattern})"
        echo "  Add: echo '$file' >> .gitignore"
        FAILED=1
      fi
    fi
  done
done <<< "$STAGED_FILES"

# ── 3. Large binary / LFS ────────────────────────────────────────────────────
SIZE_LIMIT=$((500 * 1024))

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue

  if command -v stat &>/dev/null; then
    file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
  else
    file_size=0
  fi

  if [[ $file_size -gt $SIZE_LIMIT ]]; then
    if command -v git-lfs &>/dev/null || git lfs version &>/dev/null 2>&1; then
      if ! git lfs ls-files 2>/dev/null | grep -qF "$file"; then
        size_mb=$(awk "BEGIN {printf \"%.1f\", $file_size/1048576}")
        echo -e "${RED}[LFS]${NC} '$file' is ${size_mb}MB — track with git-lfs:"
        echo "  git lfs track '$file' && git add .gitattributes"
        FAILED=1
      fi
    else
      size_mb=$(awk "BEGIN {printf \"%.1f\", $file_size/1048576}")
      echo -e "${RED}[LFS]${NC} '$file' is ${size_mb}MB and git-lfs is not installed."
      echo "  Install git-lfs or remove this file from the commit."
      FAILED=1
    fi
  fi
done <<< "$STAGED_FILES"

# ── Result ───────────────────────────────────────────────────────────────────
if [[ $FAILED -ne 0 ]]; then
  echo ""
  echo -e "${RED}Pre-commit checks failed.${NC} Fix the issues above and retry."
  exit 1
fi

exit 0
```

Save to: `config/git-hooks/pre-commit`

Make executable:
```bash
chmod +x config/git-hooks/pre-commit
```

- [ ] **Step 2: Update `install_git_hook` in `install`**

Find this function in `install`:
```bash
function install_git_hook() {
  local src="$SOURCE_DIR/config/git-hooks/pre-commit-secret-scan"
  local dest="$SOURCE_DIR/.git/hooks/pre-commit"
  [[ -f "$src" ]] || return
  symlink "$src" "$dest"
  chmod +x "$src"
}
```

Replace with:
```bash
function install_git_hook() {
  local src="$SOURCE_DIR/config/git-hooks/pre-commit"
  local dest="$SOURCE_DIR/.git/hooks/pre-commit"
  [[ -f "$src" ]] || return
  symlink "$src" "$dest"
  chmod +x "$src"
}
```

- [ ] **Step 3: Delete old hook file**

```bash
git rm config/git-hooks/pre-commit-secret-scan
```

- [ ] **Step 4: Re-run install to wire up the new hook**

```bash
./install
```

Expected: `[ok] Linked pre-commit` in output. Verify:
```bash
ls -la .git/hooks/pre-commit
```
Expected: symlink pointing to `config/git-hooks/pre-commit`

- [ ] **Step 5: Smoke test the hook**

Verify the hook script syntax is valid and the symlink is live:

```bash
bash -n config/git-hooks/pre-commit && echo "syntax OK"
ls -la .git/hooks/pre-commit
```

Expected: `syntax OK` and a symlink pointing to `config/git-hooks/pre-commit`.

To manually test secret detection: stage any file containing a real AWS key pattern and the hook will block the commit. Do not embed matching secret patterns in documentation.

- [ ] **Step 6: Commit**

```bash
git add config/git-hooks/pre-commit install
git commit -m "replace pre-commit-secret-scan with unified pre-commit hook

Adds .gitignore hygiene and LFS checks alongside secrets scan.
All three checks are hard blocks (exit 1)."
```

---

### Task 7: Remove Stop hook `post-agent-reminder` from `config/settings.json`

**Files:**
- Modify: `config/settings.json`

The `post-agent-reminder` Stop hook is replaced by the `post-implementation-review` skill. Remove it.

- [ ] **Step 1: Remove the Stop hook entry from settings.json**

Find in `config/settings.json`:
```json
"Stop": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/hooks/post-agent-reminder",
        "timeout": 5
      }
    ]
  }
],
```

Remove the entire `"Stop"` key and its array value. If Stop has other hooks, remove only the `post-agent-reminder` entry.

- [ ] **Step 2: Delete the hook file**

```bash
git rm config/hooks/post-agent-reminder
```

- [ ] **Step 3: Validate settings.json is still valid JSON**

```bash
node -e "require('./config/settings.json'); console.log('valid JSON')"
```
Expected: `valid JSON`

- [ ] **Step 4: Commit**

```bash
git add config/settings.json
git commit -m "remove post-agent-reminder Stop hook

Replaced by post-implementation-review skill invocation."
```

---

## Parallel execution note

Tasks 1–5 have zero shared state. Dispatch them in parallel via `dispatching-parallel-agents`.
Task 6 (pre-commit) and Task 7 (settings.json) are also independent of each other — dispatch in parallel with group 1–5 or as a second parallel wave.
