In all interactions and commit messages, be extremely concise, and sacrifice grammar for the sake of concision.

Never mention Claude Code authorship in commits. No "Generated with Claude Code", no "Co-Authored-By: Claude", nothing.

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
