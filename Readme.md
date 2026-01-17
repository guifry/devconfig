# devconfig

Cross-platform terminal environment. One command setup.

## Setup

### macOS
```bash
curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

### Ubuntu / Debian
```bash
sudo apt update && sudo apt install -y curl && curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

### Fedora / RHEL / CentOS
```bash
curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

### Arch
```bash
curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

### Alpine
```bash
apk add curl bash git && curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

Prompts for **light** (terminal: zsh, tmux, vim, rg, claude) or **full** (+ SSH keys, Python).

---

## What the Setup Does

1. **Checks git** — prompts install instructions if missing
2. **Installs Nix** — via Determinate Systems installer, handles:
   - macOS (ARM/Intel)
   - Linux with systemd
   - Linux without systemd (containers, WSL1) — uses `--init none`
3. **Clones this repo** to `~/projects/devconfig`
4. **Backs up existing dotfiles** — ~/.zshrc, ~/.tmux.conf, ~/.vimrc, ~/.gitconfig to `~/.dotfiles-backup/<timestamp>/`
5. **Runs home-manager** — installs packages, symlinks configs
6. **Sets up aliases** — symlinks selected categories to `~/.aliases.d/`
7. **Installs Claude Code** — via official installer
8. **Full setup only:** SSH key wizard + Python (uv)

---

## Design Constraints

| Constraint | How It's Handled |
|------------|------------------|
| Works on macOS ARM | `darwin-arm64` flake config, `aarch64-darwin` pkgs |
| Works on macOS Intel | `darwin-x86` flake config, `x86_64-darwin` pkgs |
| Works on Linux x86 | `linux-x86` flake config, `x86_64-linux` pkgs |
| Works on Linux ARM | `linux-arm64` flake config, `aarch64-linux` pkgs |
| Works without systemd | Nix install with `--init none`, manual daemon start |
| Works in containers | USER/HOME env vars set if missing |
| Backs up before overwriting | `~/.dotfiles-backup/<timestamp>/` with user confirmation |
| Warns about auto-wipe | Prompts user about org backup policies |
| Clipboard cross-platform | pbcopy on macOS, xclip on Linux |
| Headless servers | Warns xclip won't work if no $DISPLAY |
| Non-destructive | Never force-overwrites, always prompts |
| Reversible | home-manager generations, backup restore, nix uninstall |
| Idempotent | Safe to re-run, skips already-installed components |
| SSH key backup | Backs up existing keys before generating new |
| Dynamic username | Uses $USER env var, works on any server |

---

## Uninstall / Rollback

### Rollback to previous config
```bash
# List generations
home-manager generations

# Activate a previous generation (copy the path from above)
/nix/store/xxx-home-manager-generation/activate
```

### Restore backed-up dotfiles
```bash
# Find your backup
ls ~/.dotfiles-backup/

# Restore
cp ~/.dotfiles-backup/<timestamp>/* ~/
```

### Uninstall Nix completely
```bash
/nix/nix-installer uninstall
```

### Remove devconfig
```bash
rm -rf ~/projects/devconfig
rm -rf ~/.aliases.d
```

---

## Commands

```bash
make doctor       # Check status, install missing components
make switch       # Apply config changes
make update       # Update nixpkgs + apply
make clean        # Garbage collect old generations
make setup-light  # Re-run light setup
make setup-full   # Re-run full setup
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
