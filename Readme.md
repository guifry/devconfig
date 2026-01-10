# devconfig

Cross-platform dotfiles and dev environment setup.

## Quick start

### Option 1: Nix (recommended, cross-platform)

```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone and setup
git clone git@github.com:guifry/devconfig.git ~/projects/devconfig
cd ~/projects/devconfig
make setup
```

Auto-detects macOS (ARM/Intel) and Linux.

### Option 2: Legacy script (macOS only)

```bash
./setup.sh
source ~/.zshrc
```

Copies config files but doesn't install packages.

## Commands

```bash
make setup    # First-time bootstrap
make switch   # Apply config changes
make update   # Update nixpkgs + apply
make clean    # Garbage collect old generations
```

## What's included

**Packages:** tmux, vim, git, curl, jq, ripgrep, fzf, direnv

**Configs:**
- zsh: auto-starts tmux
- tmux: `Ctrl+]` prefix, vi keys, hjkl pane nav
- vim: relative line numbers, system clipboard
- direnv: nix-shell integration

**Not managed by Nix:**
- macOS GUI apps (iTerm2, VSCode) — install manually or via Homebrew
- ~/.secrets — local tokens, not committed

## Secrets

Local secrets stored in `~/.secrets`, sourced by `.zshrc`. See `.secrets.example`.

## GitHub CLI (multi-account)

Personal account default everywhere. Work account auto-activates in work folders.

### Setup

```bash
# Login both accounts
gh auth login   # personal (guifry)
gh auth login   # work (gforey-ext)

# Get personal token → ~/.secrets
gh auth switch -u guifry
gh auth token   # copy to GH_TOKEN in ~/.secrets

# Get work token → ~/kpler/.envrc
gh auth switch -u gforey-ext
gh auth token   # copy to GH_TOKEN in ~/kpler/.envrc
direnv allow ~/kpler

# Default to personal
gh auth switch -u guifry
```

### Test

```bash
cd ~/projects/anything    # → guifry
cd ~/kpler/any-repo       # → gforey-ext
```

## SSH config

`~/.ssh/config`:
```
Host github.com-guifry
  HostName github.com
  User git
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_ed25519_guifry

Host github.com-gforey-ext
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_kpler

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519_kpler
```

For personal repos: `git@github.com-guifry:guifry/repo.git`

## Cheatsheets

- [tmux](tmux-cheatsheet.md)
- [vim](vim-cheatsheet.md)
