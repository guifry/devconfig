# Codex config

Codex shares the same instructions and prompts as the other agents:

| Path | Symlinked to |
|------|--------------|
| `~/.codex/AGENTS.md` | `agents/shared/instructions.md` |
| `~/.codex/prompts` | `agents/shared/commands` |
| `~/.agents/skills` | `agents/shared/skills` |

**Verified** against Codex CLI 0.142 (installed via `cask "codex"`):

- Codex reads global instructions from `~/.codex/AGENTS.md` (it skips empty files,
  so the old empty placeholder was inert). The symlink replaces it.
- Codex reads user skills from `~/.agents/skills` (canonical) and, for backwards
  compatibility, legacy `~/.codex/skills`. Symlinked skill folders are followed.
- `~/.codex/skills` is deliberately NOT managed: it holds the app's `.system`
  skills (recreated by the app) and codex-only skills (`keep-codex-fast`,
  `opencode-delegation-orchestrator`). agent-sync prunes it.
- `~/.codex/prompts` is unverified — keep it, confirm later.

`~/.codex/config.toml` is not managed — add it here and symlink it from `home.nix`
once its schema is confirmed.

## Skills caveat

Auto-triggering on a skill's `description` is Claude Code behaviour. Codex can
choose skills implicitly too (its metadata load is similar), but treat the shared
skills as readable prompt files you invoke explicitly. Four skills call
Claude-only orchestration tools (`Agent`, `Task`, `TaskCreate`, `TaskUpdate`,
`Skill`) and will not run here:

- `batch-execute`
- `standup-prep`
- `ralph-plan`
- `ralph-review`

## Codex-only skills (stay in `~/.codex/skills`)

Skills tied to the Codex app itself or to Codex-only workflows stay in
`~/.codex/skills` — never in `agents/shared/`:

- `.system/` — app-managed system skills (imagegen, skill-creator, …)
- `keep-codex-fast` — maintains Codex's own app storage
- `opencode-delegation-orchestrator` — Codex orchestrating opencode

`av-cli` moved to `agents/shared/skills/` (tool-global, any repo). The Kpler
`chartering-integration-tests` skill moved to web-app's `.agents/skills`
(repo-scoped, where Codex discovers it only in that repo).
