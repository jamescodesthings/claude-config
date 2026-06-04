---
name: legal-review
description: Dep/data legal check — warn only, never block
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
