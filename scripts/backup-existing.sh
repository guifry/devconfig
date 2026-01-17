#!/bin/bash

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

files_to_check=(
  ~/.zshrc
  ~/.tmux.conf
  ~/.vimrc
  ~/.gitconfig
  ~/.ssh/config
)

existing=()
for f in "${files_to_check[@]}"; do
  [[ -f "$f" && ! -L "$f" ]] && existing+=("$f")
done

if [[ ${#existing[@]} -gt 0 ]]; then
  echo ""
  echo "The following files will be overwritten:"
  for f in "${existing[@]}"; do echo "  $f"; done
  echo ""
  echo "Backup location: $BACKUP_DIR"
  echo ""
  echo "WARNING: Some organisations auto-wipe folders outside designated paths."
  echo "Ensure backup location won't be purged, or copy backups elsewhere."
  echo ""
  read -p "Continue? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 2
  fi

  mkdir -p "$BACKUP_DIR"
  for f in "${existing[@]}"; do
    cp "$f" "$BACKUP_DIR/"
    echo "Backed up: $(basename "$f")"
  done
  echo ""
  echo "Restore with: cp $BACKUP_DIR/* ~/"
  echo ""
fi
