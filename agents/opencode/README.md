# opencode config

`opencode.json` holds opencode-specific settings (MCP servers, permissions, the
`review` subagent). Instructions and prompts are shared with the other agents:

| Path | Symlinked to |
|------|--------------|
| `~/.config/opencode/opencode.json` | `agents/opencode/opencode.json` |
| `~/.config/opencode/AGENTS.md` | `agents/shared/instructions.md` |
| `~/.config/opencode/command` | `agents/shared/commands` |
| `~/.config/opencode/skills` | `agents/shared/skills` |
| `~/.config/opencode/plugin` | `agents/opencode/plugin` |

**Verified** against 1.18.27: config discovery globs `{command,commands}/**/*.md`,
`{skill,skills}/**/SKILL.md` and `{plugin,plugins}/*.{ts,js}`, all with symlinks
followed, so both the singular and plural spellings work.

**Known wart:** opencode also scans `~/.claude/skills` and `~/.agents/skills`
unconditionally, and dedupes on absolute glob path. Since all three point at the
same directory through different symlinks, every shared skill is probably
discovered three times. Dropping the `~/.config/opencode/skills` symlink would
likely fix it. Not done — unmeasured, and harmless beyond listing noise.
Opt-outs if it becomes annoying: `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1`,
`OPENCODE_DISABLE_EXTERNAL_SKILLS=1`.

## Destructive-command guard

`plugin/guard.js` implements `tool.execute.before` and throws to abort the call.
It delegates to `agents/shared/guard/check-command.sh` — see CLAUDE.md.

Why a plugin rather than `permission.bash` globs alone: the glob rules are
anchored full-string matches against tree-sitter-parsed sub-commands, so
`foo && rm -rf ~` is caught by `rm *` but `sudo rm -rf ~`, `/bin/rm -rf ~` and
`bash -c "rm -rf ~"` are not. The plugin sees the raw string. The deny globs in
`opencode.json` stay as a coarse second layer.

`--dangerously-skip-permissions` does not defeat either: it is a hidden alias for
`--auto`, which only auto-answers permission *prompts*, and a `deny` rule
short-circuits before any prompt is published. The plugin hook runs earlier
still, before permission evaluation.

Config and plugins load once at startup — restart opencode after changing them.

## Known duplication

The `review` agent defined in `opencode.json` overlaps with the `review-*` skills
in `agents/shared/skills/`. Same intent, two incompatible formats. Nothing
resolves this automatically — pick one as primary when it starts to matter.

## Skills caveat

Auto-triggering on a skill's `description` is Claude Code behaviour. opencode has
no equivalent, so skills land as readable prompt files you invoke explicitly. Four
skills call Claude-only orchestration tools and will not run here: `batch-execute`,
`standup-prep`, `ralph-plan`, `ralph-review`.
