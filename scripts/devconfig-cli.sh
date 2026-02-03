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
    echo "Applying brew packages..."
    brew bundle --file="$REPO/Brewfile"
  fi

  if [[ "$IS_DARWIN" == "true" ]] && [ -d "/Applications/AeroSpace.app" ]; then
    echo "Registering AeroSpace as login item..."
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/AeroSpace.app", hidden:false}' 2>/dev/null || true
  fi

  echo "Syncing nvim plugins..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

  echo ""
  echo "Done. Run 'reload' or open new terminal to apply shell changes."

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
  echo "4) status  - Show nix store size + generations"
  echo "5) clean   - Garbage collect old generations"
  echo "6) edit    - Open home.nix in editor"
  echo "q) quit"
  echo ""
  read -p "Select: " choice < /dev/tty

  case $choice in
    1|switch)  cmd_switch ;;
    2|update)  cmd_update ;;
    3|doctor)  cmd_doctor ;;
    4|status)  cmd_status ;;
    5|clean)   cmd_clean ;;
    6|edit)    cmd_edit ;;
    q|quit)    exit 0 ;;
    *)         echo "Invalid option" ;;
  esac
}

case "${1:-}" in
  switch)  cmd_switch ;;
  update)  cmd_update ;;
  doctor)  cmd_doctor ;;
  status)  cmd_status ;;
  clean)   cmd_clean ;;
  edit)    cmd_edit ;;
  help|-h|--help)  cmd_help ;;
  "")      show_menu ;;
  *)       echo "Unknown command: $1"; cmd_help; exit 1 ;;
esac
