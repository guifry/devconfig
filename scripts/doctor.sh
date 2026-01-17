#!/bin/bash

echo "Devconfig Doctor"
echo "================"

check() {
  local name=$1
  local cmd=$2
  if command -v "$cmd" &> /dev/null; then
    echo "[OK] $name"
    return 0
  else
    echo "[--] $name"
    return 1
  fi
}

missing=()

echo ""
echo "Light Setup:"
check "nix" "nix" || missing+=("nix")
check "home-manager" "home-manager" || missing+=("home-manager")
check "zsh" "zsh" || missing+=("zsh")
check "tmux" "tmux" || missing+=("tmux")
check "vim" "vim" || missing+=("vim")
check "ripgrep" "rg" || missing+=("ripgrep")
check "fd" "fd" || missing+=("fd")
check "fzf" "fzf" || missing+=("fzf")
check "direnv" "direnv" || missing+=("direnv")
check "claude" "claude" || missing+=("claude")

echo ""
echo "Full Setup:"
if [[ -f ~/.ssh/id_ed25519_personal ]] || [[ -f ~/.ssh/id_ed25519 ]]; then
  echo "[OK] SSH keys"
else
  echo "[--] SSH keys"
  missing+=("ssh")
fi
check "uv (python)" "uv" || missing+=("uv")

echo ""
echo "Alias Categories:"
if [[ -d ~/.aliases.d ]] && [[ -n "$(ls -A ~/.aliases.d 2>/dev/null)" ]]; then
  for f in ~/.aliases.d/*.sh; do
    echo "[OK] $(basename "$f" .sh)"
  done
else
  echo "[--] No alias categories enabled"
fi

echo ""
if [[ ${#missing[@]} -eq 0 ]]; then
  echo "All components installed!"
else
  echo "Missing: ${missing[*]}"
  echo ""
  read -p "Install missing components? [y/N]: " install < /dev/tty
  if [[ "$install" =~ ^[Yy]$ ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    REPO_DIR="$(dirname "$SCRIPT_DIR")"
    cd "$REPO_DIR"

    needs_light=false
    needs_full=false

    for m in "${missing[@]}"; do
      case $m in
        nix|home-manager|zsh|tmux|vim|ripgrep|fd|fzf|direnv|claude)
          needs_light=true ;;
        ssh|uv)
          needs_full=true ;;
      esac
    done

    if $needs_light; then
      if ! command -v nix &> /dev/null; then
        echo "Nix not installed. Run bootstrap first:"
        echo "  curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash"
        exit 1
      fi
      make setup-light
    fi
    if $needs_full; then
      [[ " ${missing[*]} " =~ " ssh " ]] && ./scripts/ssh-setup.sh
      [[ " ${missing[*]} " =~ " uv " ]] && ./scripts/python-setup.sh
    fi
  fi
fi
