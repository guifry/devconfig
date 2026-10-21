# opencode config

`opencode.json` holds opencode-specific settings (MCP servers, permissions, the
`review` subagent). Instructions and prompts are shared with the other agents:

| Path | Symlinked to |
|------|--------------|
| `~/.config/opencode/opencode.json` | `agents/opencode/opencode.json` |
| `~/.config/opencode/AGENTS.md` | `agents/shared/instructions.md` |
| `~/.config/opencode/command` | `agents/shared/commands` |
| `~/.config/opencode/skills` | `agents/shared/skills` |

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

Not wired here. `agents/shared/guard/check-command.sh` is used by the Claude Code
hook and Codex; opencode relies on the `permission.bash` deny globs in
`opencode.json` alone.

A V1 plugin adapter used to live in `agents/opencode/plugin/guard.js`. It broke on
the V2 plugin API (V1 returned a hook object; V2 needs `export default { id, setup }`)
and surfaced as "Plugin failed" on every start, so it was removed rather than
ported. The globs it added coverage over: `sudo rm -rf ~`, `/bin/rm -rf ~`,
`bash -c "rm -rf ~"` — anchored full-string matches against tree-sitter-parsed
sub-commands, so those still slip past the deny list.

`--dangerously-skip-permissions` does not defeat the globs: it is a hidden alias
for `--auto`, which only auto-answers permission *prompts*, and a `deny` rule
short-circuits before any prompt is published.

Config loads once at startup — restart opencode after changing it.

## Known duplication

The `review` agent defined in `opencode.json` overlaps with the `review-*` skills
in `agents/shared/skills/`. Same intent, two incompatible formats. Nothing
resolves this automatically — pick one as primary when it starts to matter.

## Skills caveat

Auto-triggering on a skill's `description` is Claude Code behaviour. opencode has
no equivalent, so skills land as readable prompt files you invoke explicitly. Four
skills call Claude-only orchestration tools and will not run here: `batch-execute`,
`standup-prep`, `ralph-plan`, `ralph-review`.
