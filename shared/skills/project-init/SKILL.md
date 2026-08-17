---
name: project-init
description: Use when initializing a new project (claude init, first run in a directory, or on request) or when asked to sync/update a project's instructions against agent-forge's current rules. Gives the required CLAUDE.md structure, the project memory directory seeding steps, and points to PROJECT_INIT.md for syncing an existing project.
---

## Syncing an existing project's instructions

If asked to update, sync, or refresh a project's `CLAUDE.md`/`AGENTS.md` against agent-forge's current rules (not a from-scratch init), this is **not** this skill's job to do inline — follow `PROJECT_INIT.md` in the agent-forge repo (`~/projects/personal/agent-forge/PROJECT_INIT.md` unless a different path is given). It has the full diff/changelog/Q&A process for reconciling a project that's already diverged. Everything below this point is for a genuinely new project only.

## Project CLAUDE.md

When creating or populating a `CLAUDE.md` for a project (via `claude init`, first run in a directory, or on request), always use this structure:

```markdown
# CLAUDE.md

[One sentence: what this project is and what it does.]

## Stack

[Languages, frameworks, key dependencies — the minimum needed to orient a new dev.]

## Local setup

​```bash
# minimal setup commands
​```

## Testing

​```bash
# how to run tests
​```

## Post-implementation checks

<!-- post-implementation-review skill reads this section and appends its checks to the standard ones -->
<!-- Add project-specific checks here. Examples: -->
<!-- - Run database migrations: `npm run migrate` -->
<!-- - Verify API contract: `npm run test:contract` -->
<!-- - Check bundle size: `npm run analyze` -->
```

The `## Post-implementation checks` section is required — it's the hook the `post-implementation-review` skill uses to run project-specific checks after every code-changing agent. Leave it present even if empty. Fill in project-specific commands as the project evolves.

## Project Memory Seeding

When initializing a new project (via `claude init`, first run in a directory, or on request), seed the project memory directory alongside the CLAUDE.md.

The memory directory lives at `~/.claude/projects/<encoded-path>/memory/` where `<encoded-path>` is the project path with `/` replaced by `-`. For `/Users/alice/projects/myapp`, that's `~/.claude/projects/-Users-alice-projects-myapp/memory/`. Memory files go directly in `memory/` — no subdirectories.

**Seed steps:**

1. Create the memory directory if it doesn't exist
2. Create `MEMORY.md` as an empty index:

```markdown
# Project Memory
```

3. Create an initial `project_context.md` capturing what you know about the project from its CLAUDE.md:

```markdown
---
name: project-context
description: Core project identity — stack, purpose, key conventions
metadata:
  type: project
---

[Fill in: what the project is, its stack, any non-obvious conventions discovered during init.]
```

Fill in the body from the CLAUDE.md. Global user/feedback memories are already available via `~/.claude/memory/` — do not copy them here.
