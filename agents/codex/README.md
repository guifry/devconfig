# Codex config

Codex shares the same instructions and prompts as the other agents:

| Path | Symlinked to |
|------|--------------|
| `~/.codex/AGENTS.md` | `agents/shared/instructions.md` |
| `~/.codex/prompts` | `agents/shared/commands` |
| `~/.codex/skills` | `agents/shared/skills` |

**Unverified.** Codex was not installed when these symlinks were written. Confirm
the paths against your installed version, then correct `home.nix` if they differ.

`~/.codex/config.toml` is not managed — add it here and symlink it from `home.nix`
once its schema is confirmed.

## Skills caveat

Auto-triggering on a skill's `description` is Claude Code behaviour. Codex has no
equivalent, so skills land as readable prompt files you invoke explicitly. Four
skills call Claude-only orchestration tools (`Agent`, `Task`, `TaskCreate`,
`TaskUpdate`, `Skill`) and will not run here:

- `batch-execute`
- `standup-prep`
- `ralph-plan`
- `ralph-review`
