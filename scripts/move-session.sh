#!/usr/bin/env bash
set -euo pipefail

SESSION_ID="1b0c8ea0-5cf6-4c8f-8644-0b18d4d74319"
SRC="$HOME/.claude/projects/-Users-guilhemforey"
DST="$HOME/.claude/projects/-Users-guilhemforey-projects-devconfig"
BACKUP="$HOME/.claude/projects/session-move-backup"

FILE="$SRC/$SESSION_ID.jsonl"

if lsof "$FILE" &>/dev/null; then
  echo "Session file still open by a process. Close Claude Code first, then re-run."
  exit 1
fi

mkdir -p "$BACKUP" "$DST"

echo "Backing up..."
cp "$FILE" "$BACKUP/"
[ -d "$SRC/$SESSION_ID" ] && cp -r "$SRC/$SESSION_ID" "$BACKUP/"

echo "Moving session to devconfig project..."
mv "$FILE" "$DST/"
[ -d "$SRC/$SESSION_ID" ] && mv "$SRC/$SESSION_ID" "$DST/"

echo "Done. Backup at: $BACKUP"
echo "Resume with: cd ~/projects/devconfig && claude --continue"
