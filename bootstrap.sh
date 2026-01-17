#!/bin/bash
set -e

echo "Devconfig Setup"
echo "==============="
echo "1) Light - terminal experience (zsh, tmux, vim, rg, claude code)"
echo "2) Full  - light + SSH keys + Python environment"
read -p "Choice [1/2]: " choice

if ! command -v git &> /dev/null; then
  echo "Git required. Install with:"
  [[ "$OSTYPE" == darwin* ]] && echo "  xcode-select --install"
  [[ -f /etc/debian_version ]] && echo "  sudo apt install git"
  [[ -f /etc/redhat-release ]] && echo "  sudo dnf install git"
  exit 1
fi

if ! command -v nix &> /dev/null; then
  echo "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
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
read -p "Select [e.g. 1 3 4]: " alias_choice
export ALIAS_CATEGORIES="$alias_choice"

if [[ "$choice" == "2" ]]; then
  make setup-full
else
  make setup-light
fi
