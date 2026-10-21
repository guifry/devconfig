// opencode adapter for the shared destructive-command guard.
//
// Hooks run before the tool's own permission evaluation, so a throw aborts the
// call regardless of --dangerously-skip-permissions (which is only an alias for
// --auto, and only auto-answers permission prompts).
//
// Both hooks are registered because neither covers every path on its own: a
// tool-driven shell fires both, while a bare shell created through the API fires
// only `create.before`. Hooking the shell domain also means the name of the
// agent-facing shell tool does not matter.
//
// Unlike permission bash globs, this sees the raw command string, so it catches
// `sudo rm -rf ~`, `/bin/rm -rf ~` and `bash -c "rm -rf ~"`, none of which the
// anchored glob patterns match.

import { execFileSync } from "node:child_process"
import { existsSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const GUARD = join(homedir(), "projects", "devconfig", "agents", "shared", "guard", "check-command.sh")

let previous = { command: "", at: 0 }

function inspect(command) {
  if (!command.trim()) return
  // Absent means uninstalled on purpose; present-but-broken is a fault, and a
  // safety check that faults must not quietly mean "carry on".
  if (!existsSync(GUARD)) return
  if (command === previous.command && Date.now() - previous.at < 2000) return
  previous = { command, at: Date.now() }

  try {
    execFileSync(GUARD, [command], { stdio: ["ignore", "pipe", "pipe"], timeout: 5000 })
  } catch (error) {
    const reason =
      error?.status === 1
        ? String(error.stdout ?? "").trim() || "matched a blocked pattern"
        : `guard malfunctioned (${error?.code ?? error?.status ?? "unknown"}), refusing to run this command`
    throw new Error(
      `BLOCKED by devconfig guard: ${reason}\n` +
        `Command: ${command}\n` +
        "If this is genuinely intended, run it yourself, or `guard off` to disarm for 15 min.",
    )
  }
}

export default {
  id: "devconfig.guard",
  async setup(ctx) {
    await ctx.tool.hook("execute.before", (event) => {
      inspect(String(event.input?.command ?? ""))
    })
    await ctx.shell.hook("create.before", (event) => {
      inspect(String(event.command ?? ""))
    })
  },
}