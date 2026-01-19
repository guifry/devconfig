#!/bin/bash

REPO="${DEVCONFIG_PATH:-$HOME/projects/devconfig}"

if [ ! -d "$REPO" ]; then
  echo "Error: devconfig repo not found at $REPO"
  echo "Set DEVCONFIG_PATH or clone to ~/projects/devconfig"
  exit 1
fi

cd "$REPO"

# Detect platform
UNAME=$(uname)
ARCH=$(uname -m)
if [[ "$UNAME" == "Darwin" ]]; then
  [[ "$ARCH" == "arm64" ]] && CONFIG="darwin-arm64" || CONFIG="darwin-x86"
else
  [[ "$ARCH" == "aarch64" ]] && CONFIG="linux-arm64" || CONFIG="linux-x86"
fi

cmd_switch() {
  echo "Applying config..."
  home-manager switch --impure --flake ".#$CONFIG"
}

cmd_update() {
  echo "Updating nixpkgs..."
  nix flake update
  home-manager switch --impure --flake ".#$CONFIG"
}

cmd_doctor() {
  ./scripts/doctor.sh
}

cmd_clean() {
  echo "Cleaning old generations..."
  nix-collect-garbage -d
}

cmd_edit() {
  ${EDITOR:-vim} "$REPO/home.nix"
}

cmd_help() {
  echo "devconfig - manage your dev environment"
  echo ""
  echo "Usage: devconfig [command]"
  echo ""
  echo "Commands:"
  echo "  switch    Apply config changes"
  echo "  update    Update nixpkgs + apply"
  echo "  doctor    Check installed components"
  echo "  clean     Garbage collect old generations"
  echo "  edit      Open home.nix in editor"
  echo ""
  echo "Run without arguments for interactive menu."
}

show_menu() {
  echo "devconfig"
  echo "========="
  echo ""
  echo "1) switch  - Apply config changes"
  echo "2) update  - Update nixpkgs + apply"
  echo "3) doctor  - Check installed components"
  echo "4) clean   - Garbage collect old generations"
  echo "5) edit    - Open home.nix in editor"
  echo "q) quit"
  echo ""
  read -p "Select: " choice < /dev/tty

  case $choice in
    1|switch)  cmd_switch ;;
    2|update)  cmd_update ;;
    3|doctor)  cmd_doctor ;;
    4|clean)   cmd_clean ;;
    5|edit)    cmd_edit ;;
    q|quit)    exit 0 ;;
    *)         echo "Invalid option" ;;
  esac
}

# Main
case "${1:-}" in
  switch)  cmd_switch ;;
  update)  cmd_update ;;
  doctor)  cmd_doctor ;;
  clean)   cmd_clean ;;
  edit)    cmd_edit ;;
  help|-h|--help)  cmd_help ;;
  "")      show_menu ;;
  *)       echo "Unknown command: $1"; cmd_help; exit 1 ;;
esac
