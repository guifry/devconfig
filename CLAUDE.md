# DEVCONFIG - Claude Code Instructions

## CRITICAL: READ THIS FIRST

**devconfig is ADDITIVE ONLY.** It supplements the user's machine. It NEVER deletes, removes, or modifies anything outside its own scope.

The user has software, packages, and configurations installed independently of devconfig. These are NOT managed by devconfig and must NEVER be touched.

### What devconfig IS:
- A portable dev environment supplement
- Adds dotfiles (zsh, neovim, tmux, git, ghostty, aerospace)
- Adds coding-agent config (Claude Code, opencode, Codex) from one shared source
- Adds nix packages (cross-platform CLI tools)
- Adds brew casks on macOS (GUI apps only, declared in Brewfile)
- Version controlled, reproducible

### What devconfig is NOT:
- A complete system configuration manager
- A replacement for the user's existing setup
- Authorised to delete ANYTHING
- Authorised to manage packages the user installed independently

## FORBIDDEN ACTIONS

**NEVER do any of the following:**

1. **NEVER use `cleanup`, `zap`, or any destructive brew options**
2. **NEVER use nix-darwin** (it requires sudo, modifies system files, breaks things)
3. **NEVER remove packages not declared in devconfig**
4. **NEVER modify /etc/ files or system-level configurations**
5. **NEVER run commands with sudo unless explicitly requested**
6. **NEVER assume devconfig should manage everything on the machine**

## Architecture

```
devconfig/
├── flake.nix                    # Nix flake - build targets per platform
├── home.nix                     # Home-manager config - dotfiles + nix packages (CROSS-PLATFORM)
├── Brewfile                     # macOS brew casks only - GUI apps (ADDITIVE ONLY)
├── nvim/init.lua                # Neovim (kickstart.nvim: lazy.nvim + LSP + treesitter + telescope)
├── aerospace.toml               # AeroSpace tiling WM (modifier = Ctrl+Alt)
├── ghostty.config               # Ghostty terminal (the local terminal)
├── lazygit.yml                  # lazygit keybindings
├── agents/                      # ALL coding-agent config (see below)
│   ├── shared/                  # One source, fanned out to every agent
│   │   ├── instructions.md      # Global user instructions
│   │   ├── commands/            # Slash commands (8)
│   │   └── skills/              # Skills (36)
│   ├── claude/                  # Claude-only: settings.json, hooks/
│   ├── opencode/                # opencode.json + README
│   └── codex/                   # README (config.toml not yet managed)
├── macos/                       # macOS app configs (restored on switch)
│   ├── mouseless-config.yaml    # Mouseless keyboard mouse control
│   ├── homerow.plist            # Homerow keyboard navigation
│   ├── default-folder-x.plist   # Default Folder X enhanced dialogs
│   └── click2minimize.plist     # Click2Minimize Finder behaviour
├── macos-manual-apps.md         # Apps that must be installed by hand
├── macos-licenses.md.template   # Template for license key storage (real file gitignored)
├── scripts/
│   ├── devconfig-cli.sh         # `devconfig` - the environment manager (switch/update/doctor)
│   ├── dcli                     # `dcli` - the Python CLI (agent-guide TUI), via uv
│   ├── doctor.sh                # Health check
│   ├── rx                       # Ralph autonomous loop runner
│   └── ax/ox/tx/vx/xx           # Cheat sheets (aerospace/orgmode/tmux/vim/index)
├── aliases/                     # Opt-in alias categories → ~/.aliases.d/
├── conventions/chartering/      # Work coding standards, symlinked into worktrees by `fst`
├── workspaces/kpler/            # `fst` - multi-repo worktree creator
├── devconfig-cli/               # Python: agent-guide block DB + TUI
├── clippy/                      # Python: macOS clipboard history daemon
├── prompt-reformat/             # Python: Groq hotkey prompt rewriter
└── CLAUDE.md                    # This file
```

### agents/ (Coding agent config)

Claude Code, opencode and Codex are used interchangeably, so instructions,
commands and skills live once in `agents/shared/` and `home.nix` symlinks them
into each agent's expected location:

| Source | Claude Code | opencode | Codex |
|--------|-------------|----------|-------|
| `shared/instructions.md` | `~/.claude/CLAUDE.md` | `~/.config/opencode/AGENTS.md` | `~/.codex/AGENTS.md` |
| `shared/commands/` | `~/.claude/commands` | `~/.config/opencode/command` | `~/.codex/prompts` |
| `shared/skills/` | `~/.claude/skills` | `~/.config/opencode/skills` | `~/.codex/skills` |

Because these are directory symlinks, a skill or command created by any agent
lands directly in this repo.

**Caveats:**
- Auto-triggering on a skill's `description` is Claude Code behaviour. Elsewhere
  skills are readable prompt files you invoke explicitly.
- Four skills use Claude-only orchestration tools (`Agent`, `Task`, `TaskCreate`,
  `TaskUpdate`, `Skill`) and will not run under the others: `batch-execute`,
  `standup-prep`, `ralph-plan`, `ralph-review`.
- The opencode and Codex paths above are **unverified** — neither was installed
  when they were written. Confirm before trusting them.
- **NOT managed**: `~/.claude/sounds/`, `~/.claude/plugins/`, `~/.claude/projects/`,
  `~/.claude/cache/` — these stay local.

### Global vs project-scoped skills

**devconfig holds global skills only** — ones wanted in every project regardless of
what is being worked on. A skill tied to one repo (hardcoded paths, one team's
conventions) belongs in that repo's own `.claude/skills/`, never here. Global skills
load into every session on the machine and consume space in the skill listing, so the
bar is: *would this make any sense in an unrelated repo?*

To add a command: create `agents/shared/commands/my-command.md`
To add a skill: create `agents/shared/skills/my-skill/SKILL.md` (uppercase — the
filesystem here is case-insensitive but Linux targets are not)

### Keeping agent config in sync (`agent-sync`)

Because `~/.claude/skills` is a symlink, a skill created by an agent lands in this
repo automatically — but **untracked**. It then exists on one machine only, and
`home-manager switch` builds from the git tree, so it never actually applies.

`agent-sync` (also `devconfig sync`) checks four things:

1. Managed paths still symlink into devconfig — an agent may have replaced one
2. Skills sitting in user-scope agent dirs but outside devconfig
3. Filename casing (`SKILL.md`)
4. Uncommitted changes under `agents/`

Report-only by default; `agent-sync --fix` moves stray skills in and corrects casing.
It never deletes and never overwrites an existing destination. It deliberately does
**not** scan project repos — project skills are meant to stay where they are.

A `Stop` hook in `agents/claude/settings.json` prints a one-line reminder whenever
`agents/` is dirty, so drift surfaces without having to remember the command.

### Ralph Workflow (Autonomous Coding Loop)

External bash loop spawning fresh claude sessions per iteration. Each session gets a clean 200K context window.

**Flow**: `/ralph-plan` → `/ralph-launch` → `rx` runs → `/ralph-status` → `/ralph-review`

1. `/ralph-plan` — decompose feature into PRD.json (atomic stories)
2. `/ralph-launch` — generate PROMPT.md, initialise progress.txt, start `rx`
3. `rx` — bash loop: for each iteration, pipes PROMPT.md into a fresh `claude --dangerously-skip-permissions` session
4. `/ralph-status` — check progress (story table, commits, blockers)
5. `/ralph-review` — review all commits against acceptance criteria, run tests, verdict

## Modules

### home.nix (Cross-platform)
- **Scope**: Dotfiles and nix packages
- **Platforms**: macOS + Linux
- **Contains**:
  - `home.packages`: CLI tools installed via nix (ripgrep, fd, jq, etc.)
  - `programs.zsh`: Shell config, aliases, functions
  - `programs.tmux`: Tmux config, keybindings. Auto-starts in local Ghostty
    (keyed off `$GHOSTTY_RESOURCES_DIR`); over SSH, start it manually.
  - `xdg.configFile`: Neovim (kickstart.nvim), Ghostty (local terminal),
    AeroSpace (tiling WM), lazygit, opencode
  - `home.file."bin/*"`: utility scripts installed to `~/bin` — this is the only
    installer for them, bootstrap.sh does not copy them
  - `programs.git`: Git config, aliases, ignores
  - `programs.fzf`: Fuzzy finder config
  - `programs.direnv`: Directory environments

**Platform conditionals**: Use `lib.optionals isDarwin` or `lib.optionals (!isDarwin)` for platform-specific packages/config.

### Brewfile (macOS only)
- **Scope**: GUI applications (casks) ONLY
- **MUST be additive**: Only installs what's declared, NEVER removes other packages
- **Format**: Standard Brewfile syntax
```
cask "app-name"
```

**DO NOT add `brew cleanup`, `--cleanup`, or any removal logic.**

### flake.nix
- **Scope**: Build definitions
- **Configurations**:
  - `darwin-arm64`: Apple Silicon Mac
  - `darwin-x86`: Intel Mac
  - `linux-x86`: x86 Linux
  - `linux-arm64`: ARM Linux

## Workflows

### User: Apply config changes
```bash
devconfig switch
```
This runs:
1. `home-manager switch` (nix packages + dotfiles)
2. `brew bundle` on macOS (installs declared casks, touches nothing else)
3. `nvim --headless "+Lazy! sync" +qa` (sync neovim plugins)

### User: Update dependencies
```bash
devconfig update
```
This runs:
1. `nix flake update` (update nix inputs)
2. `brew update` on macOS (update brew index)
3. `devconfig switch` (apply updates)

### User: Check health
```bash
devconfig doctor
```

### User: Clean old generations
```bash
devconfig clean
```
This runs `nix-collect-garbage -d` and `brew cleanup` (cache only, NOT packages).

### User: Edit config
```bash
devconfig edit
```
Opens home.nix in editor.

## Adding Packages

### CLI tools (cross-platform): Add to home.nix
```nix
home.packages = with pkgs; [
  existing-packages
  new-package      # Add here
];
```

### macOS GUI apps: Add to Brewfile
```
cask "new-app"
```

### Platform-specific CLI tools:
```nix
home.packages = with pkgs; [
  # common packages
] ++ lib.optionals isDarwin [
  macos-only-package
] ++ lib.optionals (!isDarwin) [
  linux-only-package
];
```

## Adding Shell Aliases/Functions

In home.nix under `programs.zsh.initContent`:
```nix
initContent = ''
  alias myalias='command'

  function myfunc () {
    # function body
  }
'';
```

## Adding Neovim Plugins

Edit `nvim/init.lua`. Plugins are managed by lazy.nvim inside the `require('lazy').setup({...})` call.
Add a new entry to the plugin spec table:
```lua
{ 'author/plugin-name', opts = {} },
```

## Adding Tmux Config

In home.nix under `programs.tmux.extraConfig`:
```nix
extraConfig = ''
  bind x command
'';
```

## How Config Reaches the Machine (read before editing home.nix)

Two different mechanisms, and the distinction matters:

| Mechanism | Used for | Effect of an edit |
|-----------|----------|-------------------|
| `mkOutOfStoreSymlink` (helpers `repoFile` / `agentFile`) | nvim, aerospace, ghostty, lazygit, all of `agents/` | `~/.config/...` points **back into this repo**. Edits are live immediately, no rebuild. |
| `home.file."bin/x" = { source = ./scripts/x; }` | everything in `~/bin` | Copied into the nix store. Edits need `devconfig switch`. |

Consequences a future agent must know:

- Because `~/.claude/skills` is a *directory* symlink, a skill created by any agent
  lands in this repo automatically — but **untracked**. See `agent-sync` above.
- `~/bin` scripts are **only** installed by `home.nix`. Do not add `cp` lines to
  bootstrap.sh — copying over a nix-store symlink fails silently.
- Adding a new script means two steps: create `scripts/x`, then add a
  `home.file."bin/x"` entry. It will not appear otherwise.

## Testing Changes

1. Make changes to home.nix, Brewfile, or any nix-managed file
2. **Commit changes first** — `home-manager switch` builds from the git tree, uncommitted changes are ignored
3. Run `devconfig switch`
4. If shell changes: run `reload` or open new terminal
5. If nvim changes: restart nvim

### Testing a branch before merging

`bootstrap.sh` normally refuses to run if the repo has uncommitted changes or
unpushed commits, and it does `git pull --ff-only`. That blocks testing a branch.
Use `--local` to bootstrap from the current checkout as-is:

```bash
./bootstrap.sh --local
```

For an already-bootstrapped machine, `devconfig switch` has no such guard — it
builds whatever is checked out. Commit first (see above), then switch.

## Platform Detection

`uname` + `uname -m` select the flake target. All four are defined in `flake.nix`:

| Machine | Config |
|---------|--------|
| Apple Silicon Mac | `darwin-arm64` |
| Intel Mac | `darwin-x86` |
| Linux x86 | `linux-x86` |
| Linux ARM | `linux-arm64` |

`--impure` is required on every home-manager invocation because `home.nix` reads
`$USER` and `$HOME` via `builtins.getEnv`. This is deliberate — it keeps the config
username-agnostic. **Never hardcode a home path** (`/Users/<name>/...`) anywhere in
this repo; use the `repoDir` / `repoFile` helpers, `~`, or `$HOME`.

## Known Gaps

Honest list, so nobody rediscovers these:

- **opencode and Codex config paths are unverified.** Both tools are now installed
  (`brew "opencode"`, `cask "codex"`), but the symlinks in `home.nix` for
  `~/.config/opencode/{command,skills}` and `~/.codex/{prompts,skills}` were written
  before either existed. Confirm the paths against the installed versions. Also worth
  testing whether they read `~/.claude/` natively — if so, those symlinks are redundant.
- **`~/.codex/config.toml` is not managed.** Codex has no config in this repo yet.
- **Node comes from nixpkgs, not nvm.** `nodejs` is in `home.packages`. nvm is
  deliberately not used — `mise` is already installed and handles per-project node
  versions. `programs.zsh` still sources nvm if you install it by hand.
- **`claude-code-acp` is installed by `devconfig switch`**, not by nix — npm's global
  prefix is inside the read-only nix store, so it goes to `~/.local` via
  `npm install -g --prefix ~/.local`. `nvim/init.lua` resolves it with
  `vim.fn.exepath` and falls back to `npx` if absent. Never hardcode an nvm path.
- **`.vimrc` is unmanaged.** Neovim is the managed editor. `bootstrap.sh` only runs
  vim-plug if a `~/.vimrc` already exists.
- **`review-web-app-pr`, `review-chartering-api`, `lint-web-app-pr`** are global
  skills that are only useful in Kpler repos. They span several repos, so no single
  project is the right home; `conventions/chartering/review-skills/` + `fst` symlinks
  would be the natural fit. Not moved — it is a change to the work setup, not cleanup.
- **`prompt-reformat` is not wired up.** Its launchd plist is a `.template` with a
  `__HOME__` placeholder; nothing installs it.
- **macOS key repeat needs a logout.** `configureKeyboard` writes `KeyRepeat`,
  `InitialKeyRepeat` and `ApplePressAndHoldEnabled` to `NSGlobalDomain`, but macOS
  caches that domain per process at launch. Running apps keep the old behaviour until
  relaunched; the login session until you log out. The values being "not applied" is
  almost always this, not a failed write — check with
  `defaults read NSGlobalDomain KeyRepeat` before debugging further.
- **Mouseless config applies on the second switch.** The cask installs it, but
  `home.activation.configureMouseless` skips silently until the app has been launched
  once and created its container directory. Launch it, then switch again.

## Troubleshooting

### "command not found" after switch
Run `reload` or open a new terminal.

### Nix build errors
Check syntax in home.nix. Common issues:
- Missing semicolons
- Unclosed strings (especially multiline)
- `''` in nix strings must be escaped as `''''`

### Brew bundle fails
Check Brewfile syntax. Each line should be `cask "name"` or `brew "name"`.

## Remember

**This config is the user's portable dev environment supplement. It lives alongside their existing setup. It adds, it never removes. If in doubt, ask the user before making changes that could affect anything outside devconfig's scope.**
