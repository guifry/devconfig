#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ALIASES_SRC="$REPO_DIR/aliases"
ALIASES_DST="$HOME/.aliases.d"

mkdir -p "$ALIASES_DST"

get_category() {
  case $1 in
    1) echo "chartering" ;;
    2) echo "kpler" ;;
    3) echo "macos-apps" ;;
    4) echo "personal" ;;
    *) echo "" ;;
  esac
}

if [[ -z "$ALIAS_CATEGORIES" ]]; then
  echo "Alias categories:"
  echo "1) chartering  - chartering-fix, chartering-lint"
  echo "2) kpler       - kpler work aliases"
  echo "3) macos-apps  - windsurf, mac app shortcuts"
  echo "4) personal    - fst, personal utils"
  read -p "Select (space-separated, or 'none'): " ALIAS_CATEGORIES
fi

[[ "$ALIAS_CATEGORIES" == "none" ]] && exit 0

for num in $ALIAS_CATEGORIES; do
  cat=$(get_category "$num")
  [[ -z "$cat" ]] && continue
  src="$ALIASES_SRC/${cat}.sh"
  dst="$ALIASES_DST/${cat}.sh"
  if [[ -f "$src" ]]; then
    ln -sf "$src" "$dst"
    echo "Enabled: $cat"
  else
    echo "Warning: $src not found"
  fi
done
