---
name: orca-worktree-cleanup-done
description: Clean up what this session created that nothing else uses, then move the Orca worktree/workspace to Done.
disable-model-invocation: true
---

Clean up after yourself, then move this workspace to Done in Orca.

1. List what this session created: scratch databases, containers, extra git worktrees, background processes. Use the conversation and your scratchpad.
2. An item is yours only if the conversation shows you creating it, or its path contains this session's scratchpad. A similar-looking name is not proof. No record? Keep it.
3. Remove it only if nothing else uses it: re-check just before deleting (open connections, running processes, other sessions).
4. Never touch:
   - this workspace's own folder, branch or uncommitted work;
   - any worktree with uncommitted or unpushed work, and any branch;
   - shared services (local Supabase or Docker stacks), the main checkout, other worktrees, the git stash;
   - anything remote: environments, branches, PRs.
5. Delete with the owning tool, by exact name or id: `git worktree remove <path>`, `DROP DATABASE <name>`, `docker rm <id>`, `kill <pid>` (only a pid you started; check its command first). Never `rm -rf`, `--force`, `pkill -f`, `docker prune`, `docker volume rm` or `docker compose down`. If `git worktree remove` refuses only over files you put there yourself (a copied `.env`, a `.venv` link), `rm` those exact paths first. Leave scratchpad files.
6. Load the `orca-cli` skill. Set this workspace's status to Done (`completed` by default) with a one-line comment, and `--pr <n>` if `gh pr list --head <branch> --state all` finds one: `worktree set --worktree active --workspace-status completed --comment "..." --pr <n> --json`. Confirm with `worktree show`.
7. Report what you removed, what you kept and why.
