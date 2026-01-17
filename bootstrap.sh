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
[ -d "$REPO" ] || git clone https://github.com/guifry/devconfig.git "$REPO"

cd "$REPO"

echo ""
echo "Alias categories (space-separated numbers, or 'none'):"
echo "1) chartering  - chartering-fix, chartering-lint"
echo "2) kpler       - kpler work aliases"
echo "3) macos-apps  - windsurf, mac app shortcuts"
echo "4) personal    - fst, personal utils"
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
