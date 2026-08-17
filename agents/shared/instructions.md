In all interactions and commit messages, be extremely concise, and sacrifice grammar for the sake of concision.

Never mention Claude Code authorship in commits. No "Generated with Claude Code", no "Co-Authored-By: Claude", nothing.

Commit messages are strict one-liners. Format: `verb: description`. No body, no paragraphs, no multi-line.

At the end of each plan, give me a list of unresolved questions if any. Make the questions extremely concise, but still precise. Sacrifice grammar for the sake of concision.

<When coding>
Don't write comments. Unless necessary (linter/typing ignore), or really valuable (edge case or complexity that must be documented for developers). British english only.
</When coding>
<When creating new projects>
Use direnv + nix-shell for setting up the project's environment and tooling.
If a monorepo, same applies: nix-shell and direnv in root folder.
</When creating new projects>
<python>
Use UV for dependencies management.
Python version must be the latest stable v3.X.
Ensure proper usage of virtual environment.
Never run pip commands that will pollute the global python scope.
Virtual environment must be in the .gitignore.


Never import within a code block or a function. Always top of module. Unless necessary because of lazy loading or circular dependencies.

Project dependencies must be easily configurable: URLs, env variables, credentials, secrets etc. Don't import them straight from the consumer code. Have a config module instead.
Load them from a .env file.
</python>
<file-operations>
When copying/moving existing files, use bash cp/mv. Never rewrite file contents manually — it's wasteful and error-prone.
</file-operations>
<creating-skills-and-commands>
All agent config lives in ~/projects/devconfig/agents/. It is shared by Claude Code, opencode and Codex — ~/.claude/skills, ~/.config/opencode/skills and ~/.codex/skills are all symlinks to agents/shared/skills.

devconfig holds GLOBAL skills only — ones wanted in every project, regardless of what is being worked on.

Where new work goes:
- Global, useful in any repo → `~/projects/devconfig/agents/shared/skills/<name>/SKILL.md` (or `commands/<name>.md`). Writing to ~/.claude/skills/ reaches the same place via the symlink; either is fine.
- Tied to one project — hardcoded paths, one repo's conventions, one team's standards → that repo's own `.claude/skills/`. NEVER put it in devconfig. A skill that is useless outside a single repo does not belong in the global set: it loads into every session everywhere and takes up room in the skill listing.

If unsure: ask whether the skill would make any sense in an unrelated repo. If no, it is project-scoped.

Rules:
- Filename is `SKILL.md`, uppercase. This filesystem is case-insensitive; Linux targets are not.
- Never use an absolute home path (`/Users/<name>/...`). Use `~` or a relative path.
- After creating or editing anything under devconfig/agents/, commit it. Uncommitted skills exist on one machine only, and `home-manager switch` builds from the git tree.
- These four skills use Claude-only tools (Agent, Task, TaskCreate, TaskUpdate, Skill) and will not run under opencode or Codex: batch-execute, standup-prep, ralph-plan, ralph-review. Avoid those tools in new skills unless the skill is deliberately Claude-only.

Run `agent-sync` to check for skills that ended up outside devconfig, and `agent-sync --fix` to pull them in.
</creating-skills-and-commands>
