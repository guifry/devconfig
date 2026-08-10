#!/bin/bash

REPO="${DEVCONFIG_PATH:-$HOME/projects/devconfig}"

if [ ! -d "$REPO" ]; then
  echo "Error: devconfig repo not found at $REPO"
  echo "Set DEVCONFIG_PATH or clone to ~/projects/devconfig"
  exit 1
fi

cd "$REPO"

export NIX_CONFIG="experimental-features = nix-command flakes"

UNAME=$(uname)
ARCH=$(uname -m)
IS_DARWIN=false

if [[ "$UNAME" == "Darwin" ]]; then
  IS_DARWIN=true
  [[ "$ARCH" == "arm64" ]] && CONFIG="darwin-arm64" || CONFIG="darwin-x86"
else
  [[ "$ARCH" == "aarch64" ]] && CONFIG="linux-arm64" || CONFIG="linux-x86"
fi

# Homebrew's installer does not add itself to PATH on Apple Silicon, and a shell
# started before home-manager ran will not have it either. Look in the known
# locations before concluding it is absent — otherwise brew bundle is skipped
# silently and no GUI apps get installed.
ensure_brew_on_path() {
  command -v brew &>/dev/null && return 0
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

run_home_manager() {
  if command -v home-manager &>/dev/null; then
    home-manager "$@"
  else
    nix run home-manager -- "$@"
  fi
}

cmd_switch() {
  echo "Applying nix config..."
  run_home_manager switch --impure --flake ".#$CONFIG" || return 1

  if [[ "$IS_DARWIN" == "true" && -f "$REPO/Brewfile" ]]; then
    if ensure_brew_on_path; then
      echo "Applying brew packages..."
      brew tap nikitabobko/tap 2>/dev/null || true
      brew update
      if ! brew bundle --file="$REPO/Brewfile" --verbose; then
        echo ""
        echo "########################################################"
        echo "# brew bundle FAILED — GUI apps are NOT installed.     #"
        echo "# Fix the error above, then re-run: devconfig switch   #"
        echo "########################################################"
        return 1
      fi
    else
      echo ""
      echo "########################################################"
      echo "# Homebrew not found — GUI apps were NOT installed.    #"
      echo "# (AeroSpace, Ghostty, Raycast, Bloom, Maccy, Kap...)   #"
      echo "# Install Homebrew, then re-run: devconfig switch      #"
      echo "########################################################"
      echo ""
    fi
  fi

  if [[ "$IS_DARWIN" == "true" ]] && [ -d "/Applications/AeroSpace.app" ]; then
    echo "Registering AeroSpace as login item..."
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/AeroSpace.app", hidden:false}' 2>/dev/null || true
  fi

  # codecompanion's Claude adapter needs the ACP bridge on PATH. Installed to
  # ~/.local (already on PATH) rather than npm's global prefix, which is inside the
  # read-only nix store.
  if command -v npm &>/dev/null; then
    if ! command -v claude-code-acp &>/dev/null; then
      echo "Installing claude-code-acp (codecompanion Claude adapter)..."
      npm install -g --prefix "$HOME/.local" @zed-industries/claude-code-acp \
        || echo "  WARNING: install failed — codecompanion falls back to npx"
    fi
  else
    echo "WARNING: npm not found — skipping claude-code-acp"
  fi

  # Get nvim fully usable before it is opened by hand: plugins, then LSP servers,
  # formatters and debug adapters. Treesitter parsers install during the Lazy step
  # (nvim-treesitter is lazy=false and blocks on install in its config).
  echo "Syncing nvim plugins..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

  # Only pay for this when something is actually missing — otherwise every switch
  # would sit through the async-install fallback. Names match `ensure_installed`
  # in nvim/init.lua; keep the two in sync.
  MASON_PKGS="$HOME/.local/share/nvim/mason/packages"
  mason_missing=false
  for tool in basedpyright ruff typescript-language-server lua-language-server stylua tree-sitter-cli debugpy; do
    [ -e "$MASON_PKGS/$tool" ] || mason_missing=true
  done

  if [ "$mason_missing" = true ]; then
    echo "Installing LSPs, formatters and debug adapters (mason, first run only)..."
    nvim --headless "+MasonToolsInstallSync" +qa 2>/dev/null \
      || nvim --headless "+MasonToolsInstall" "+sleep 90" +qa 2>/dev/null \
      || echo "  (incomplete — mason will finish on first nvim launch)"
  else
    echo "LSPs and formatters already installed (mason)."
  fi

  echo ""
  echo "Done. Run 'reload' or open new terminal to apply shell changes."

  if [[ "$IS_DARWIN" == "true" ]]; then
    echo ""
    echo "NOTE: key repeat settings (fast backspace) are written to NSGlobalDomain,"
    echo "      but macOS caches them per process. Already-running apps keep the old"
    echo "      behaviour until relaunched, and the login session until you log out."
    echo "      Log out and back in to apply everywhere."
  fi

  if [[ "$IS_DARWIN" == "true" && -f "$REPO/macos-manual-apps.md" ]]; then
    echo ""
    echo "─────────────────────────────────────"
    echo "MANUAL APPS (install these yourself):"
    echo "─────────────────────────────────────"
    awk '/^# macOS Manual Apps/,/^# macOS Manual Config/{if(/^## /)print "  • " substr($0,4)}' "$REPO/macos-manual-apps.md"
    echo ""
    echo "─────────────────────────────────────"
    echo "MANUAL CONFIG (installed, import config via app UI):"
    echo "─────────────────────────────────────"
    awk '/^# macOS Manual Config/,0{if(/^## /)print "  • " substr($0,4)}' "$REPO/macos-manual-apps.md"
    echo ""
    echo "See $REPO/macos-manual-apps.md for details."
  fi
}

cmd_update() {
  echo "Updating flake inputs..."
  nix flake update

  if [[ "$IS_DARWIN" == "true" ]]; then
    echo "Updating brew..."
    brew update
  fi

  cmd_switch
}

cmd_doctor() {
  ./scripts/doctor.sh
}

cmd_sync() {
  ./scripts/agent-sync "$@"
}

cmd_clean() {
  echo "Cleaning old nix generations..."
  nix-collect-garbage -d

  if [[ "$IS_DARWIN" == "true" ]]; then
    echo "Cleaning brew cache..."
    brew cleanup
  fi
}

cmd_edit() {
  ${EDITOR:-nvim} "$REPO/home.nix"
}

cmd_status() {
  echo "Nix Store"
  echo "========="
  echo "Size: $(du -sh /nix/store 2>/dev/null | cut -f1)"
  echo ""
  echo "Generations:"
  ls -la ~/.local/state/nix/profiles/home-manager-* 2>/dev/null | wc -l | xargs echo "Count:"
  ls -lt ~/.local/state/nix/profiles/home-manager-* 2>/dev/null | head -5

  if [[ "$IS_DARWIN" == "true" ]]; then
    echo ""
    echo "Brew"
    echo "===="
    echo "Packages: $(brew list | wc -l | xargs)"
    echo "Casks: $(brew list --cask | wc -l | xargs)"
  fi
}

cmd_help() {
  echo "devconfig - manage your dev environment"
  echo ""
  echo "Usage: devconfig [command]"
  echo ""
  echo "Commands:"
  echo "  switch    Apply config changes"
  echo "  update    Update flake inputs + brew + apply"
  echo "  doctor    Check installed components"
  echo "  sync      Check agent skills/commands are in devconfig (--fix to pull them in)"
  echo "  status    Show nix store size + generations"
  echo "  clean     Garbage collect old generations"
  echo "  edit      Open home.nix in editor"
  echo ""
  echo "Config files:"
  echo "  home.nix  - Nix packages + dotfiles (cross-platform)"
  echo "  Brewfile  - macOS brew packages"
  echo ""
  echo "Run without arguments for interactive menu."
}

show_menu() {
  echo "devconfig"
  echo "========="
  echo ""
  echo "1) switch  - Apply config changes"
  echo "2) update  - Update flake inputs + brew + apply"
  echo "3) doctor  - Check installed components"
  echo "4) sync    - Check agent skills/commands are in devconfig"
  echo "5) status  - Show nix store size + generations"
  echo "6) clean   - Garbage collect old generations"
  echo "7) edit    - Open home.nix in editor"
  echo "q) quit"
  echo ""
  read -p "Select: " choice < /dev/tty

  case $choice in
    1|switch)  cmd_switch ;;
    2|update)  cmd_update ;;
    3|doctor)  cmd_doctor ;;
    4|sync)    cmd_sync ;;
    5|status)  cmd_status ;;
    6|clean)   cmd_clean ;;
    7|edit)    cmd_edit ;;
    q|quit)    exit 0 ;;
    *)         echo "Invalid option" ;;
  esac
}

case "${1:-}" in
  switch)  cmd_switch ;;
  update)  cmd_update ;;
  doctor)  cmd_doctor ;;
  sync)    shift; cmd_sync "$@" ;;
  status)  cmd_status ;;
  clean)   cmd_clean ;;
  edit)    cmd_edit ;;
  help|-h|--help)  cmd_help ;;
  "")      show_menu ;;
  *)       echo "Unknown command: $1"; cmd_help; exit 1 ;;
esac
