#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ALIASES_SRC="$REPO_DIR/aliases"
ALIASES_DST="$HOME/.aliases.d"

mkdir -p "$ALIASES_DST"

IS_SERVER=false
[[ "${DEVCONFIG_MODE:-}" == "server" ]] && IS_SERVER=true

get_category() {
  case $1 in
    1) echo "chartering" ;;
    2) echo "kpler" ;;
    3) [[ "$IS_SERVER" == true ]] || echo "macos-apps" ;;
    4) echo "personal" ;;
    *) echo "" ;;
  esac
}

if [[ -z "$ALIAS_CATEGORIES" ]]; then
  echo "Alias categories:"
  echo "1) chartering  - chartering-fix, chartering-lint"
  echo "2) kpler       - fst, kpler work env"
  [[ "$IS_SERVER" == true ]] || echo "3) macos-apps  - windsurf, mac app shortcuts"
  echo "4) personal    - loadzsh, personal utils"
  read -p "Select (space-separated, or 'none'): " ALIAS_CATEGORIES < /dev/tty
fi

[[ "$ALIAS_CATEGORIES" == "none" ]] && exit 0

# Support both "1 2 3" and "1,2,3" formats
ALIAS_CATEGORIES="${ALIAS_CATEGORIES//,/ }"

for num in $ALIAS_CATEGORIES; do
  if [[ "$num" == "3" && "$IS_SERVER" == true ]]; then
    echo "Skipping macos-apps on server"
    continue
  fi
  cat=$(get_category "$num")
  [[ -z "$cat" ]] && continue
  src="$ALIASES_SRC/${cat}.sh"
  dst="$ALIASES_DST/${cat}.sh"
  if [[ -f "$src" ]]; then
    ln -sf "$src" "$dst"
    echo "Enabled: $cat"

    # kpler category: also install fst command
    if [[ "$cat" == "kpler" ]]; then
      mkdir -p ~/bin
      ln -sf "$REPO_DIR/workspaces/kpler/create-fullstack-wt.py" ~/bin/fst
      echo "Installed: fst command"
    fi
  else
    echo "Warning: $src not found"
  fi
done
