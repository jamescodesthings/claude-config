---
name: secrets-check
description: Use before committing or staging files to check for secrets, credentials, or sensitive data that must not enter the repo. Triggers on: about to commit, staging changes, "is it safe to commit", reviewing files for sensitive content, handling tokens/API keys/passwords.
---

# Secrets Check

Run before any commit. Decide whether sensitive data belongs in the repo — or somewhere safe.

## Step 1: Scan staged changes

```bash
git diff --staged
```

Look for:
- Tokens: `ghp_`, `sk-`, `xoxb-`, `xoxp-`, `AKIA`, `ya29.`
- Keys: `-----BEGIN`, `private_key`, `secret_key`, `rsa`
- Named secrets: patterns like `*_TOKEN`, `*_SECRET`, `*_KEY`, `*_PASSWORD`, `*_CREDENTIAL`
- `settings.json` env block — any key whose value looks like a credential

## Step 2: Decide where each secret belongs

| Content | Safe location | NOT in git? |
|---------|--------------|-------------|
| API tokens, PATs, passwords | `config/env.local` (gitignored) | ✓ |
| Machine-specific paths | Normalized at install time | ✓ |
| Non-secret config | `config/settings.json` | Committed ✓ |
| Plugin names, themes, hooks | `config/settings.json` | Committed ✓ |

## Step 3: Act

**Secret found in staged file:**
1. `git reset HEAD <file>` to unstage
2. Move secret to `config/env.local` (copy from `config/env.local.example` if it doesn't exist)
3. Add the file to `.gitignore` if appropriate
4. Re-stage the clean version

**Secret found in `settings.json` env block:**
1. Remove from settings.json
2. Add to `config/env.local` instead
3. Document in `config/env.local.example` with a commented-out example line

**Unsure if something is a secret:** treat it as one. Secrets in git cannot be fully removed from history without a force-push that rewrites it.

## config/env.local

Gitignored file for per-machine credentials. Not auto-sourced — user exports manually or sources in shell profile.

```bash
# config/env.local
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
```

To use: `source config/env.local` or add to `~/.zshenv`.
