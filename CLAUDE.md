# DEVCONFIG - Claude Code Instructions

## CRITICAL: READ THIS FIRST

**devconfig is ADDITIVE ONLY.** It supplements the user's machine. It NEVER deletes, removes, or modifies anything outside its own scope.

The user has software, packages, and configurations installed independently of devconfig. These are NOT managed by devconfig and must NEVER be touched.

### What devconfig IS:
- A portable dev environment supplement
- Adds dotfiles (zsh, vim, tmux, git, wezterm, aerospace)
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
├── flake.nix                    # Nix flake - defines build targets per platform
├── home.nix                     # Home-manager config - dotfiles + nix packages (CROSS-PLATFORM)
├── Brewfile                     # macOS brew casks only - GUI apps (ADDITIVE ONLY)
├── wezterm.lua                  # WezTerm terminal config (leader = Ctrl+])
├── aerospace.toml               # AeroSpace tiling WM config (modifier = Ctrl+Alt)
├── macos/                       # macOS-specific app configs (restored on switch)
│   ├── mouseless-config.yaml    # Mouseless keyboard mouse control
│   ├── homerow.plist            # Homerow keyboard navigation
│   ├── default-folder-x.plist   # Default Folder X enhanced dialogs
│   └── click2minimize.plist     # Click2Minimize Finder behaviour
├── macos-manual-apps.md         # List of manually installed macOS apps
├── macos-licenses.md.template   # Template for license key storage
├── .gitignore                   # Ignores macos-licenses.md (sensitive)
├── scripts/
│   ├── devconfig-cli.sh         # Main CLI tool
│   ├── doctor.sh                # Health check script
│   ├── tx                       # tmux cheat sheet
│   └── vx                       # vim cheat sheet
└── CLAUDE.md                    # This file
```

## Modules

### home.nix (Cross-platform)
- **Scope**: Dotfiles and nix packages
- **Platforms**: macOS + Linux
- **Contains**:
  - `home.packages`: CLI tools installed via nix (ripgrep, fd, jq, etc.)
  - `programs.zsh`: Shell config, aliases, functions
  - `programs.vim`: Vim config, plugins
  - `programs.tmux`: Tmux config, keybindings (SSH sessions only)
  - `xdg.configFile`: WezTerm config (local terminal), AeroSpace config (tiling WM)
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
3. `vim +PlugInstall +PlugClean!` (sync vim plugins)

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

## Adding Vim Plugins

In home.nix under `programs.vim.extraConfig`, inside the plug#begin block:
```vim
Plug 'author/plugin-name'
```

## Adding Tmux Config

In home.nix under `programs.tmux.extraConfig`:
```nix
extraConfig = ''
  bind x command
'';
```

## Testing Changes

1. Make changes to home.nix or Brewfile
2. Run `devconfig switch`
3. If shell changes: run `reload` or open new terminal
4. If vim changes: restart vim

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
