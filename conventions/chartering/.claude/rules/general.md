---
description: Cross-cutting rules for all repos in FST workspaces
---

# General Rules

## Central Documentation

All documentation lives in the FST root (`docs/`), never inside individual repos. This is the single source of truth.

```
docs/
├── README.md              # Feature index — start here
├── codebase/{repo}/       # How each repo works (feature-agnostic)
└── features/{feature}/    # Feature-specific docs (fixr, etc.)
```

When working from a sub-repo (web-app, chartering-fast-api, chartering-fixing-api), docs are at `../../docs/` or `../docs/` relative to the repo root. Each sub-repo has a `.claude/rules/context.md` pointer.

## Context Loading Protocol

1. Read `CLAUDE.local.md` — current work context and priorities
2. Read `docs/features/{feature}/TODO.md` — what needs doing
3. Read `docs/README.md` — feature index, find which feature you're working on
4. Load `docs/codebase/` docs only when working in that repo
5. Load `docs/features/{feature}/` deep docs only when needed for the task

## Research Protocol

Docs are summaries — not primary sources. Before implementing anything non-trivial:

1. **Read actual code** — grep for the pattern, read the file. Code may have diverged from docs.
2. **Check referenced PRs** — if docs reference a PR, read its diff for the parts you're about to build.
3. **Check git log** — before touching a file, check recent history (`git log --oneline -10 -- <file>`).
4. **Find existing examples** — when implementing a pattern, find 2-3 existing instances in the codebase.

## Self-Update Protocol

**After any meaningful work session, update the relevant docs.** This is not optional.

| What you learned | Where to update |
|---|---|
| Codebase patterns, conventions, gotchas | `docs/codebase/{repo}/` or `.claude/rules/` |
| Feature spec, decisions, blockers | `docs/features/{feature}/` |
| Completed a task | `docs/features/{feature}/TODO.md` |
| Made an architectural decision | `docs/features/{feature}/DECISIONS.md` |
| Current priorities changed | `CLAUDE.local.md` |
| New feature documented | Add to Feature Index in `docs/README.md` |

Never put feature-specific content in the codebase layer. Never put generic codebase knowledge only in a feature folder.

## Cross-Service Awareness

Changes in one repo often require changes in others:
- **New API endpoint in backend** → update generated types in frontend
- **Schema change** → check implications across services
- **Feature knowledge changed** → update `docs/features/{feature}/` in the FST root, not in the repo
