# Codex config

Codex shares the same instructions and prompts as the other agents:

| Path | Symlinked to |
|------|--------------|
| `~/.codex/AGENTS.md` | `agents/shared/instructions.md` |
| `~/.codex/prompts` | `agents/shared/commands` |
| `~/.agents/skills` | `agents/shared/skills` |
| `~/.codex/hooks.json` | `agents/codex/hooks.json` |

**Verified** against Codex CLI 0.142 (installed via `cask "codex"`):

- Codex reads global instructions from `~/.codex/AGENTS.md` (it skips empty files,
  so the old empty placeholder was inert). The symlink replaces it.
- Codex reads user skills from `~/.agents/skills` (canonical) and, for backwards
  compatibility, legacy `~/.codex/skills`. Symlinked skill folders are followed.
- `~/.codex/skills` is deliberately NOT managed: it holds the app's `.system`
  skills (recreated by the app) and codex-only skills (`keep-codex-fast`,
  `opencode-delegation-orchestrator`). agent-sync prunes it.
- `~/.codex/prompts` is unverified — keep it, confirm later.

`~/.codex/config.toml` is not managed, and **must not be** — Codex rewrites it
itself, appending `[projects."..."] trust_level` entries as you work. Verified by
observation. Hooks therefore live in the sibling `hooks.json`, which Codex only
writes via the `/hooks` TUI pane. Project-level hooks merge with it rather than
replacing it.

## Hooks (verified against 0.152.1)

`hooks.json` registers a `PreToolUse` hook on `^Bash$` pointing at
`~/bin/codex-guard`. Facts established by testing, all counter-intuitive enough
to be worth recording:

- `PreToolUse` is a **hard gate above approval and sandbox**. It blocks even
  under `--dangerously-bypass-approvals-and-sandbox`, and with
  `approval_policy = "never"` plus `trust_level = "trusted"`.
- Only two hook outcomes do anything: `permissionDecision: "deny"` (or exit 2)
  blocks; silence with exit 0 permits. **`"allow"` is not accepted** — Codex logs
  it as a hook failure, identical to emitting garbage. `"ask"` likewise: no
  prompt, no error, command runs.
- Everything else **fails open**. Crash, timeout, missing script, malformed
  JSON → `PreToolUse Failed` and the command proceeds. A guard here must block
  explicitly on its own errors.
- Hook **trust is hash-pinned, and an untrusted hook is skipped silently** — no
  `hook:` line, no warning. The hash covers the definition in `hooks.json`
  (matcher, command string, timeout), *not* the contents of the script it points
  at. So `~/bin/codex-guard` can be edited freely; changing `hooks.json` requires
  re-trusting via `/hooks`.
- Trust can also be written declaratively, though the key embeds an absolute
  path and lives in the unmanaged config.toml:
  `[hooks.state."<abs>/hooks.json:pre_tool_use:0:0"] trusted_hash = "sha256:…"`.
- The hook receives the **un-wrapped** command: `tool_name` is literally `Bash`
  and `tool_input.command` is a string holding `rm -rf /`, not the
  `/bin/zsh -lc '…'` that Codex actually executes. This is the opposite of the
  execpolicy rules in `~/.codex/rules/`, which are prefix-only and never see
  through the shell wrapper — those are fine for allow-listing, useless for
  denial.

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
