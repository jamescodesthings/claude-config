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
