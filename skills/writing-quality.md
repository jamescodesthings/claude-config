---
name: writing-quality
description: Review user-visible prose for grammar, tone, clarity, and AI-writing patterns. Applies to UI text, error messages, log messages, emails, notifications, and docs.
---

# Writing Quality Review

Review user-facing content for grammar, tone, and AI-writing anti-patterns.

## Scope

Apply to any content a human will read:
- Frontend / UI copy (labels, headings, error messages, empty states, onboarding)
- Log messages visible to operators or end users
- Emails and notifications (transactional, push, SMS)
- Documentation and READMEs

Do NOT apply to: code identifiers, comments, commit messages, internal config values.

## Tone Rules

Target tone: **professional, friendly, concise.**

- Lead with the point — no preamble
- One idea per sentence where possible
- Friendly but not chatty — do not over-explain. Example: "Email required" not "Hey, we need your email!" and not "Please kindly provide your email address."
- No excessive punctuation (avoid `!!!`, chains of `—`, strings of ellipsis)
- Active voice preferred over passive

## Grammar and Spelling

- Fix typos, misspellings, and agreement errors
- British or American English — match whatever the project already uses. If the project is inconsistent, default to the locale of the target users. Flag remaining inconsistencies. Skip this check for non-English copy.

## AI-Writing Anti-Patterns

Flag and rewrite any of the following:

**Filler openers** — cut or restructure:
- "Additionally, …" / "Furthermore, …" / "Moreover, …"
- "It's worth noting that …" / "It's important to mention that …"
- "In conclusion, …" / "To summarise, …"

**Sycophantic or hollow affirmations** — remove entirely:
- "Certainly!" / "Absolutely!" / "Of course!" / "Great question!"
- "I'd be happy to …" / "I'm glad you asked …"

**Vague intensifiers** — cut or replace with specific language:
- "really", "very", "quite", "incredibly", "extremely"
- "highly" (unless quantified)

**Hedge stacking** — simplify. Apply this to any stacked hedges ("tends to", "arguably", "somewhat", etc.): strip when unnecessary, keep only when accuracy requires it.
- "might potentially be possible to" → "may"
- "could potentially" → "might" or restructure

**Em-dash overuse** — max one em-dash per paragraph; rewrite extras as separate sentences or commas

**Bullet-point padding** — if three or fewer items flow naturally as prose, use prose instead

**Unnecessary length / restatement** — remove sentences that restate what was just said

**Weak word choices** — replace:
- "leverage" (as a verb) → "use"
- "utilize" → "use"
- "delve" → "explore" or "look at"
- "robust" (unless comparing resilience specs) → be specific
- "seamless" → describe the actual behaviour

## Process

1. Read each piece of changed user-facing content
2. Flag instances of the above anti-patterns with a short note
3. Rewrite flagged content in place — do not just annotate. Preserve original meaning. If a rewrite would change intent or you're uncertain, flag it for author review instead of rewriting.
4. If the file is documentation, also fix any broken formatting (orphaned headers, unclosed code fences)
5. Commit writing-quality fixes separately from functional changes
