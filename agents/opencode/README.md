# opencode config

`opencode.json` holds opencode-specific settings (MCP servers, permissions, the
`review` subagent). Instructions and prompts are shared with the other agents:

| Path | Symlinked to |
|------|--------------|
| `~/.config/opencode/opencode.json` | `agents/opencode/opencode.json` |
| `~/.config/opencode/AGENTS.md` | `agents/shared/instructions.md` |
| `~/.config/opencode/command` | `agents/shared/commands` |
| `~/.config/opencode/skills` | `agents/shared/skills` |

**Unverified.** opencode was not installed when the `command`/`skills` symlinks
were written. Confirm the paths against your installed version, then correct
`home.nix` if they differ.

## Known duplication

The `review` agent defined in `opencode.json` overlaps with the `review-*` skills
in `agents/shared/skills/`. Same intent, two incompatible formats. Nothing
resolves this automatically — pick one as primary when it starts to matter.

## Skills caveat

Auto-triggering on a skill's `description` is Claude Code behaviour. opencode has
no equivalent, so skills land as readable prompt files you invoke explicitly. Four
skills call Claude-only orchestration tools and will not run here: `batch-execute`,
`standup-prep`, `ralph-plan`, `ralph-review`.
