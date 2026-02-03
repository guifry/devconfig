---
description: Launch Wolfgang dashboard to visualise parallel plan
---

Launch the Wolfgang dashboard to visualise and manage the parallelised plan for the current project.

## Pre-flight Checks

1. Check if `.claude-parallel-prompts/` exists in current working directory
2. If not found, report error: "No parallel plan found. Run /parallelize first to create one."

## Launch Dashboard

If checks pass:

1. Get absolute path of current working directory
2. Run in background: `cd ~/wolfgang && npm run dev -- -p 0` (port 0 = auto-select available port)
3. Wait for server to start (look for "Ready" or port number in output)
4. Open browser: `open http://localhost:<PORT>?path=<CWD>`

Report the URL to the user so they can access it.

## Notes

- Dashboard auto-refreshes when files in `.claude-parallel-prompts/` change
- Click nodes to view prompts and copy them
- Use chapter buttons (Verify/Commit/Rollback) to get orchestrator prompts
- If dashboard is already running for another project, it will start on a different port
