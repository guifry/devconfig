#!/bin/bash

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

files_to_backup=(
  ~/.zshrc
  ~/.tmux.conf
  ~/.vimrc
  ~/.gitconfig
  ~/.ssh/config
)

backed_up=false

for f in "${files_to_backup[@]}"; do
  if [[ -f "$f" && ! -L "$f" ]]; then
    if ! $backed_up; then
      mkdir -p "$BACKUP_DIR"
      echo "Backing up existing dotfiles to $BACKUP_DIR"
      backed_up=true
    fi
    cp "$f" "$BACKUP_DIR/"
    echo "  $(basename $f)"
  fi
done

if $backed_up; then
  echo "Restore with: cp $BACKUP_DIR/* ~/"
else
  echo "No existing dotfiles to backup"
fi
