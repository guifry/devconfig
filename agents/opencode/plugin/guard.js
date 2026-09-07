// opencode adapter for the shared destructive-command guard.
//
// `tool.execute.before` runs before the tool's own permission evaluation, so a
// throw here aborts the call regardless of --dangerously-skip-permissions
// (which is only an alias for --auto, and only auto-answers permission prompts).
//
// Unlike permission.bash globs, this sees the raw command string, so it catches
// `sudo rm -rf ~`, `/bin/rm -rf ~` and `bash -c "rm -rf ~"`, none of which the
// anchored glob patterns match.

import { execFileSync } from "node:child_process"
import { existsSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const GUARD = join(homedir(), "projects", "devconfig", "agents", "shared", "guard", "check-command.sh")

export default async () => ({
  "tool.execute.before": async (input, output) => {
    if (input?.tool !== "bash") return
    const command = String(output?.args?.command ?? "")
    if (!command.trim()) return
    // Absent means uninstalled on purpose; present-but-broken is a fault, and a
    // safety check that faults must not quietly mean "carry on".
    if (!existsSync(GUARD)) return

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
  },
})
