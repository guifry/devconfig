#!/usr/bin/env bash
set -euo pipefail

# Bootstrap shared chartering docs into an FST folder.
# Usage: ./bootstrap-fst.sh /path/to/FST-XX-feature

CONVENTIONS_DIR="$(cd "$(dirname "$0")" && pwd)"
FST_DIR="${1:?Usage: $0 /path/to/FST-folder}"

if [ ! -d "$FST_DIR" ]; then
  echo "Error: $FST_DIR does not exist"
  exit 1
fi

link() {
  local target="$1" link_path="$2"
  if [ -L "$link_path" ]; then
    echo "  skip (already symlinked): $link_path"
    return
  fi
  if [ -e "$link_path" ]; then
    echo "  ERROR: $link_path exists and is not a symlink — remove it first"
    return
  fi
  mkdir -p "$(dirname "$link_path")"
  ln -s "$target" "$link_path"
  echo "  linked: $link_path -> $target"
}

echo "Bootstrapping $FST_DIR from $CONVENTIONS_DIR"
echo ""

echo "Shared docs:"
link "$CONVENTIONS_DIR/CLAUDE.md" "$FST_DIR/CLAUDE.md"
link "$CONVENTIONS_DIR/CHARTERING_AGENT_GUIDE.md" "$FST_DIR/CHARTERING_AGENT_GUIDE.md"
link "$CONVENTIONS_DIR/.claude/rules" "$FST_DIR/.claude/rules"
link "$CONVENTIONS_DIR/docs/codebase" "$FST_DIR/docs/codebase"

echo ""
echo "Feature docs (local, created if missing):"
mkdir -p "$FST_DIR/docs/features"
[ -f "$FST_DIR/CLAUDE.local.md" ] || touch "$FST_DIR/CLAUDE.local.md"
echo "  ensured: $FST_DIR/docs/features/"
echo "  ensured: $FST_DIR/CLAUDE.local.md"

echo ""
echo "Done. Feature-specific docs go in docs/features/ and CLAUDE.local.md."
