#!/bin/bash
set -e

# Ensure USER and HOME are set (sometimes missing in containers)
export USER="${USER:-$(whoami)}"
export HOME="${HOME:-$(eval echo ~$USER)}"

echo "Devconfig Setup"
echo "==============="
echo "1) Light - terminal experience (zsh, tmux, vim, rg, claude code)"
echo "2) Full  - light + SSH keys + Python environment"
read -p "Choice [1/2]: " choice < /dev/tty

if ! command -v git &> /dev/null; then
  echo "Git required. Install with:"
  [[ "$OSTYPE" == darwin* ]] && echo "  xcode-select --install"
  [[ -f /etc/debian_version ]] && echo "  sudo apt install git"
  [[ -f /etc/redhat-release ]] && echo "  sudo dnf install git"
  exit 1
fi

if ! command -v nix &> /dev/null; then
  echo "Installing Nix..."
  if [[ "$OSTYPE" == darwin* ]]; then
    # macOS - standard install
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  elif [ -d /run/systemd/system ]; then
    # Linux with systemd - standard install
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  else
    # Linux without systemd (containers, WSL1, etc) - no init system
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none
  fi
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

  # For non-systemd Linux, may need to start daemon manually
  if [[ "$OSTYPE" != darwin* ]] && [ ! -d /run/systemd/system ]; then
    if [ ! -S /nix/var/nix/daemon-socket/socket ]; then
      echo "Starting nix daemon..."
      if command -v sudo &>/dev/null; then
        sudo nix daemon &>/dev/null &
      else
        nix daemon &>/dev/null &
      fi
      sleep 2
    fi
  fi
fi

REPO="${DEVCONFIG_PATH:-$HOME/projects/devconfig}"
mkdir -p "$(dirname "$REPO")"
if [ -d "$REPO" ]; then
  cd "$REPO"

  # Check for uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: devconfig has uncommitted changes."
    echo "Please commit or stash them first, then re-run setup."
    exit 1
  fi

  # Check for unpushed commits
  git fetch origin
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse origin/master)
  BASE=$(git merge-base HEAD origin/master)

  if [ "$LOCAL" != "$REMOTE" ] && [ "$LOCAL" != "$BASE" ]; then
    echo "Error: devconfig has local commits not pushed to origin."
    echo "Please push or reset them first, then re-run setup."
    exit 1
  fi

  echo "Updating devconfig..."
  git pull --ff-only
else
  git clone https://github.com/guifry/devconfig.git "$REPO"
  cd "$REPO"
fi

echo ""
echo "Alias categories (space-separated numbers, or 'none'):"
echo "1) chartering  - chartering-fix, chartering-lint"
echo "2) kpler       - fst, kpler work env"
echo "3) macos-apps  - windsurf, mac app shortcuts"
echo "4) personal    - loadzsh, personal utils"
read -p "Select [e.g. 1 3 4 or 1,3,4]: " alias_choice < /dev/tty
export ALIAS_CATEGORIES="$alias_choice"

# Detect platform config
UNAME=$(uname)
ARCH=$(uname -m)
if [[ "$UNAME" == "Darwin" ]]; then
  [[ "$ARCH" == "arm64" ]] && CONFIG="darwin-arm64" || CONFIG="darwin-x86"
else
  [[ "$ARCH" == "aarch64" ]] && CONFIG="linux-arm64" || CONFIG="linux-x86"
fi

# Backup existing dotfiles
./scripts/backup-existing.sh || { echo "Setup cancelled."; exit 0; }

# Warn if headless Linux (clipboard won't work)
if [[ "$UNAME" != "Darwin" ]] && [[ -z "$DISPLAY" ]] && [[ -z "$WAYLAND_DISPLAY" ]]; then
  echo ""
  echo "Note: No display detected (headless server)."
  echo "      Clipboard integration (xclip) will not work."
  echo ""
fi

# Run home-manager (--impure needed for builtins.getEnv)
echo "Running home-manager..."
nix run home-manager -- switch --impure --flake ".#$CONFIG"

# Setup aliases
./scripts/aliases-setup.sh

# Setup secrets template
if [[ ! -f ~/.secrets ]]; then
  cp .secrets.example ~/.secrets
  echo "Created ~/.secrets from template - edit with your tokens"
fi

# Setup ~/bin with utility scripts
mkdir -p ~/bin
cp scripts/tx scripts/create_script scripts/edscript ~/bin/ 2>/dev/null || true
ln -sf "$REPO/scripts/devconfig-cli.sh" ~/bin/devconfig
chmod +x ~/bin/* 2>/dev/null || true
echo "Utility scripts installed to ~/bin"

# Setup direnvrc for parent .envrc inheritance
mkdir -p ~/.config/direnv
if ! grep -q "source_up" ~/.config/direnv/direnvrc 2>/dev/null; then
  echo 'source_up_if_exists 2>/dev/null || true' >> ~/.config/direnv/direnvrc
  echo "Added source_up to direnvrc"
fi

# Install Claude Code
echo ""
echo "Installing Claude Code..."
if ! command -v claude >/dev/null 2>&1; then
  if curl -fsSL https://claude.ai/install.sh | sh; then
    echo "Claude Code installed"
  else
    echo "Warning: Claude Code install failed (non-critical)"
  fi
fi

# Full setup extras
if [[ "$choice" == "2" ]]; then
  ./scripts/ssh-setup.sh
  ./scripts/python-setup.sh
fi

echo ""
echo "Setup complete!"
echo ""
echo "To start zsh, try (in order):"
echo "  1. Restart your terminal"
echo "  2. exec zsh"
echo "  3. source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && zsh"
echo "  4. ~/.nix-profile/bin/zsh"

if [[ "$UNAME" == "Darwin" ]]; then
  echo ""
  echo "=== iTerm2 Setup (optional) ==="
  echo "To sync iTerm2 config with devconfig:"
  echo "  1. Open iTerm2 → Settings → General → Preferences"
  echo "  2. Check 'Load preferences from a custom folder or URL'"
  echo "  3. Set path to: ~/projects/devconfig/iterm"
  echo "  4. Check 'Save changes to folder when iTerm2 quits'"
fi
