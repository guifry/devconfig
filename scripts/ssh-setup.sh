#!/bin/bash

echo "SSH Key Setup"
echo "============="

mkdir -p ~/.ssh
chmod 700 ~/.ssh

generate_key() {
  local name=$1
  local email=$2
  local keyfile=~/.ssh/id_ed25519_$name

  if [[ -f "$keyfile" ]]; then
    echo "Key $keyfile already exists, skipping"
    return
  fi

  ssh-keygen -t ed25519 -C "$email" -f "$keyfile"
  echo ""
  echo "Add this public key to GitHub ($name):"
  echo "----------------------------------------"
  cat "${keyfile}.pub"
  echo "----------------------------------------"
  read -p "Press enter when done..." < /dev/tty
}

# Key names match the Host aliases in Readme.md and octo.nvim's ssh_aliases
# (nvim/init.lua) — keep all three in sync if you rename them.
read -p "Personal GitHub email (or skip): " personal_email < /dev/tty
[[ -n "$personal_email" ]] && generate_key "guifry" "$personal_email"

read -p "Work GitHub email (or skip): " work_email < /dev/tty
[[ -n "$work_email" ]] && generate_key "kpler" "$work_email"

if [[ -n "$personal_email" ]] || [[ -n "$work_email" ]]; then
  echo ""
  echo "Generating SSH config..."

  # Backup existing SSH config
  if [[ -f ~/.ssh/config ]]; then
    cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d-%H%M%S)
    echo "Backed up existing ~/.ssh/config"
  fi

  # Build new config
  SSH_CONFIG=""
  if [[ -n "$personal_email" ]]; then
    SSH_CONFIG+="Host github.com-guifry
  HostName github.com
  User git
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_ed25519_guifry

"
  fi
  if [[ -n "$work_email" ]]; then
    SSH_CONFIG+="Host github.com-gforey-ext
  HostName github.com
  User git
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_ed25519_kpler

"
  fi

  # Default host: work key, matching Readme.md
  DEFAULT_KEY="id_ed25519_kpler"
  [[ -z "$work_email" ]] && DEFAULT_KEY="id_ed25519_guifry"
  SSH_CONFIG+="Host github.com
  AddKeysToAgent yes"
  [[ "$OSTYPE" == darwin* ]] && SSH_CONFIG+="
  UseKeychain yes"
  SSH_CONFIG+="
  IdentityFile ~/.ssh/$DEFAULT_KEY
"

  echo "$SSH_CONFIG" > ~/.ssh/config
  chmod 600 ~/.ssh/config
  echo "SSH config written to ~/.ssh/config"
fi

echo ""
echo "SSH setup complete"
