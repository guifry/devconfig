#!/bin/bash
set -e

# Parse flags
LOCAL_MODE=false
for arg in "$@"; do
  case "$arg" in
    --local)
      # Use the current checkout as-is: skip the fetch/pull and the
      # clean-and-pushed guard. For testing a branch before merging.
      LOCAL_MODE=true
      ;;
    -h|--help)
      echo "Usage: ./bootstrap.sh [--local]"
      echo "  --local   Bootstrap from the current checkout without pulling from origin."
      echo "            Use when testing a branch that is not merged or pushed."
      exit 0
      ;;
  esac
done

# Ensure USER and HOME are set (sometimes missing in containers)
export USER="${USER:-$(whoami)}"
export HOME="${HOME:-$(eval echo ~$USER)}"

# Detect platform config
UNAME=$(uname)
ARCH=$(uname -m)
if [[ "$UNAME" == "Darwin" ]]; then
  [[ "$ARCH" == "arm64" ]] && CONFIG="darwin-arm64" || CONFIG="darwin-x86"
else
  [[ "$ARCH" == "aarch64" ]] && CONFIG="linux-arm64" || CONFIG="linux-x86"
fi

# Homebrew is a hard prerequisite on macOS. Check it FIRST — before prompting and
# before installing nix — so a missing brew costs nothing.
# The installer does not add itself to PATH on Apple Silicon, so look in the known
# locations before concluding it is absent.
if [[ "$UNAME" == "Darwin" ]]; then
  if ! command -v brew &>/dev/null; then
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [[ -x "$candidate" ]]; then
        eval "$("$candidate" shellenv)"
        echo "Found Homebrew at $candidate (was not on PATH)"
        break
      fi
    done
  fi

  if ! command -v brew &>/dev/null; then
    echo ""
    CMD='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    W=100
    border=$(printf '═%.0s' $(seq 1 $W))
    pad() { printf "%-${W}s" "  $1"; }
    echo "  ╔${border}╗"
    echo "  ║$(printf '%*s' $W '')║"
    echo "  ║$(pad 'Homebrew is required on macOS.')║"
    echo "  ║$(printf '%*s' $W '')║"
    echo "  ║$(pad 'GUI apps (Raycast, AeroSpace, Ghostty, etc.) are managed via brew casks.')║"
    echo "  ║$(pad 'Install Homebrew first, then re-run this script.')║"
    echo "  ║$(printf '%*s' $W '')║"
    echo "  ║$(pad "$CMD")║"
    echo "  ║$(printf '%*s' $W '')║"
    echo "  ╚${border}╝"
    echo ""
    exit 1
  fi
fi

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

# Nix may already be installed but absent from this shell's PATH (a fresh install
# only takes effect in new shells). Source it before deciding to reinstall.
if ! command -v nix &>/dev/null && [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  command -v nix &>/dev/null && echo "Found existing Nix install (was not on PATH)"
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

  if [ "$LOCAL_MODE" = true ]; then
    echo "Local mode: using current checkout ($(git rev-parse --abbrev-ref HEAD)), not pulling from origin."
  else

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
  fi
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

if [[ "$UNAME" == "Darwin" ]] && command -v brew &>/dev/null; then
  echo "Updating brew index..."
  brew update --quiet
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
  cp secrets.example ~/.secrets
  echo "Created ~/.secrets from template - edit with your tokens"
fi

# ~/bin scripts (tx, vx, rx, devconfig, dcli, ...) are installed by home-manager
# via home.file."bin/*" — nothing to do here.

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

# Install vim-plug and plugins, but only if a ~/.vimrc actually exists.
# Neovim is the managed editor (nvim/init.lua); plain vim is unmanaged.
if [[ -f ~/.vimrc ]]; then
  if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  echo "Installing vim plugins..."
  vim +PlugInstall +qall
fi

# Full setup extras
if [[ "$choice" == "2" ]]; then
  ./scripts/ssh-setup.sh
  ./scripts/python-setup.sh
  # Without these, user.useConfigOnly makes git refuse to commit anywhere.
  ./scripts/git-identity-setup
fi

# One-time mise install: standalone build in ~/.local/bin (writable, so
# `mise self-update` works — the nixpkgs copy was pinned to whatever nixpkgs
# shipped and lagged repo min_version pins). Re-run later with:
# devconfig mise-setup
echo ""
echo "Installing mise (per-project toolchain manager)..."
./scripts/devconfig-cli.sh mise-setup

# One-time heavy nvim setup: plugins, LSPs, formatters, debug adapters and the
# codecompanion ACP bridge. Done here rather than in `devconfig switch` so that
# switch stays fast. Re-run later with: devconfig nvim-setup
echo ""
echo "Preparing nvim (plugins + LSPs). This is the slow part, and only runs once."
./scripts/devconfig-cli.sh nvim-setup || echo "Warning: nvim setup incomplete — run 'devconfig nvim-setup' later"

echo ""
echo "Setup complete!"
echo ""
echo "To start zsh, try (in order):"
echo "  1. Restart your terminal"
echo "  2. exec zsh"
echo "  3. source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && zsh"
echo "  4. ~/.nix-profile/bin/zsh"
