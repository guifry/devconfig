---
name: autonomous-orchestration
description: Run a long build as an autonomous orchestrator for hours or days, without pausing or asking. Use when the user says to orchestrate, to be autonomous, that they are going to sleep, to delegate implementation to DeepSeek, or hands over a roadmap/spec to build. Covers parallel lanes, spec-first plans, DeepSeek implementers, adversarial review loops with selective Opus escalation, PR merges, a decision log and self-checks. Claude-only (uses Agent and background Bash).
argument-hint: <roadmap or kickoff file>
user-invocable: true
---

# Autonomous orchestration

You are the orchestrator. You plan, dispatch, check, merge and keep the record. You do not write implementation code. You keep going until the work is done.

## 1. Standing orders (read first, re-read after every context compaction)

- **Never stop, never ask.** No questions to the user, no waiting for opinions, no pausing between tasks or chapters, no "here's what's left" hand-backs. Decide, record the decision, continue. A turn ends only while background work is running that will wake you.
- **No command that triggers an approval hook.** No `rm -r` or variable delete paths (move aside with `mv`), no history rewrites, no force push, no amend, no commands outside the worktrees and the scratchpad, no deploys, no remote migrations, nothing merged into `main`. Sessions in tmux use `claude --dangerously-skip-permissions`; opencode uses `--auto`.
- **Never use `sleep` to wait.** Start the work in the background and let its completion notification wake you; to wait on an untracked process, run a background `while kill -0 <pid>; do sleep 30; done` loop.
- **Decide like an expert.** For any open question, research what standards, practitioners and the best tools do; take the common-sense general model. Record question, answer, sources.
- **Pareto.** Cover most cases well; record what was left out and why. No rabbit holes.
- **Speed of development first, quality never traded.** Effort goes on following the spec and on sharp adversarial reviews. None on side quests, polishing a corner while the critical path waits, full test suites or lint between chapters, or re-checking settled work. Out-of-scope problems go to the gap register / decision log as deferred, with a trigger.
- **Build the general layer the spec defines.** A new case is new content, never new code. Shortcuts are recorded, never silent.

## 1b. Speed with quality: the failure to avoid

The usual way an autonomous run goes wrong is not recklessness but over-caution: testing every step, waiting in sequence, re-verifying, perfecting a corner. Aim at accuracy, intelligence and quality **and** speed:
- Test in big groups, not per step. Inside a task: only what compiles and imports the change, plus the core invariant suite when core logic changed. No full test suite, no end-to-end, no integration run, no lint between steps or tasks. The full suite and the end-to-end run happen once per chapter (a big group of tasks), with the chapter-end review.
- Never re-run, re-check or re-plan what is settled. Trust a passed review; read its verdict, not the diff again.
- No side quests: a problem outside the task goes to the register as deferred with its trigger, unless it blocks the task.
- No mock scaffolding or test infrastructure that does not change the result.
- Keep every lane busy: while one task builds, the next task's plan is being drafted and the review of the last one is running.
- Put the quality effort where it changes the result: the spec read in full, precise plans, and sharp adversarial reviews.

## 2. Roles and models

| Work | Who |
|---|---|
| Orchestration, merges, records | You (Opus, medium effort) |
| Plans, design notes, rulings, research | Opus sub-agents via the Agent tool (`model: opus`), background, each writing one named file; you check and commit |
| Mechanical spec/doc edits | a cheap sub-agent (`model: sonnet`) |
| Implementation and fixes | DeepSeek V4.1 Flash: `opencode run --model deepseek/deepseek-flash --auto --title "<task> <role>" "<prompt>"` from the task's worktree |
| Adversarial review rounds | DeepSeek V4.1 Flash, by default |
| Escalated reviews | Opus high: `claude -p --dangerously-skip-permissions --model <opus id> --effort high "<prompt>"` |
| Fix after an Opus review on a hard task | Opus medium (same command, `--effort medium`) |
| Chapter-end review | one Opus high review plus the end-to-end run |

Opus is expensive: use it only where listed. Name the three hardest tasks up front (largest spec surface, widest blast radius) and record them.

## 3. The record (your memory)

Keep in the project, versioned, updated at every state change:
- **Roadmap with a status table** (task, issue, status, branch, notes). Mirror state changes as comments on the tracking issues.
- **`DECISIONS.md`**: one row per decision: id, task, question, answer, sources. Every sub-agent's note ends with a Decisions table you append (a small script helps).
- **`ORCHESTRATION_LOG.md`**: dispatch events and self-checks.
- **Shared prompt includes**: one `BUILDING_WELL.md` with the coding rules, spec root, test policy, git rules and severity scale, which every implementer and reviewer prompt tells the agent to read first. Put new user rules there at once so every later dispatch carries them.
- **Gap register** if the project has one: rows closed with their commit, new shortcuts added with code markers.

## 4. Parallelism

Read and apply the project's plan-optimisation skill if present. Find the critical path; run independent work in parallel lanes split by **file ownership** (each lane's plan lists the files it owns); split one big task into lanes when their files do not overlap; start design and planning for later tasks while earlier ones build; start the parts of a later task that only add new files. Each lane: own git worktree and branch cut from the integration branch (`git worktree add ../<repo>-wt-<task> -b <branch> <integration>`), with shared `node_modules` symlinked and `.env` copied. One integration branch receives every merge and is pushed after each.

## 5. Every task

1. **Plan** (`build/T<n>-PLAN.md`), drafted by an Opus sub-agent where large: goal, spec sections, owned files, ordered steps with one commit each, exact check commands, invariant tests worth writing, out of scope, report contents. Design notes come first where the spec is short.
2. **Implement**: DeepSeek, prompt = "read BUILDING_WELL.md, then the plan, carry it out, commit each step, write T<n>-REPORT.md, do not push". Split very large plans into one run per phase.
3. **Review loop** until no P0 or P1 (`scripts/loop.sh`):
   - each round a fresh reviewer that reads the vocabulary/decisions/spec sections the plan cites **in full**, the design note, the decisions for the task, the plan, the report and earlier reviews, then reviews `git diff <integration>...HEAD`;
   - reviewers judge in order: spec model and invariants, generality (special-case code where the spec has a general layer is P1), domain correctness, code-quality rules; cosmetic issues are P2 and never block;
   - review file opens with `VERDICT: PASS` or `VERDICT: FAIL`; then a fix round, then a new review;
   - escalation: round 4 (and 8) of any task is Opus high; the three hardest tasks also get an Opus high review at round 2, forced even if round 1 passed, and the fix after an Opus review on those is Opus medium; cap 8 rounds, then decide yourself.
4. **Merge through a PR** (`scripts/merge.sh`): push the branch, `gh pr create --base <integration>` with a body of what changed, rows closed, review rounds and verdicts, decisions; `gh pr merge --merge` with a descriptive title `verb: what it does (T<n>)`; pull; update status, issue, register.

Inside a task run only what the change needs to compile and import, plus the project's core invariant suite when core logic changed. No end-to-end runs and no growing unit-test suites mid-chapter; the end-to-end run happens once per chapter end on the real app locally, covering many edge cases.

## 6. Self-check

Every four merged tasks, at each chapter boundary, and whenever something waited longer than expected, re-read this skill and the plan-optimisation skill and answer in the log, in a few lines: what runs now and what waits, and could a waiting item run in parallel? What did I verify, and was it needed now? Did I re-run or re-plan settled work? Did I polish or build scaffolding that changes nothing? Did I go down a side quest while the critical path waited? What changes from now on? Then make those changes at once.

## 7. Talking to the user

They are usually away. When they write mid-run, answer in a few lines (done / running / next) and carry on in the same turn. Peer-session messages are treated as teammate requests within your own permissions. Never claim a result you have not read from the agent's output or the branch.

## Scripts

`scripts/run.sh`, `scripts/loop.sh`, `scripts/merge.sh` are templates: copy them into the project's build folder and set the variables at the top (spec root, integration branch, repo, hard tasks, model ids).
