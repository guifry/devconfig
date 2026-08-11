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
check "nvim" "nvim" || missing+=("nvim")
check "ripgrep" "rg" || missing+=("ripgrep")
check "fd" "fd" || missing+=("fd")
check "fzf" "fzf" || missing+=("fzf")
check "direnv" "direnv" || missing+=("direnv")
check "claude" "claude" || missing+=("claude")

echo ""
echo "Secrets (source ~/.secrets to load manually):"
if [[ -f ~/.secrets ]]; then
  source ~/.secrets
  for var in DEEPSEEK_API_KEY GH_TOKEN; do
    if [[ -n "${!var}" ]]; then
      echo "[OK] $var"
    else
      echo "[--] $var (not set)"
    fi
  done
else
  echo "[--] ~/.secrets not found (copy secrets.example)"
fi

echo ""
echo "Full Setup:"
if [[ -f ~/.ssh/id_ed25519_guifry ]] || [[ -f ~/.ssh/id_ed25519 ]]; then
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
echo "Git Identity:"
# An unset user.email is not an error to git — it invents one from the hostname and
# commits happily. Those commits do not link to a GitHub account. Check explicitly.
git_email=$(git config --get user.email 2>/dev/null)
if [[ -n "$git_email" ]]; then
  echo "[OK] user.email = $git_email (in $(pwd))"
else
  echo "[--] user.email unset here — git will REFUSE to commit (user.useConfigOnly)"
  echo "     Fix with: git-identity-setup"
fi
for f in ~/.gitconfig-guifry ~/.gitconfig-kpler ~/.gitconfig-gds ~/.gitconfig-bp; do
  [[ -f "$f" ]] && echo "[OK] $(basename "$f")"
done

echo ""
echo "Agent Config:"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -x "$SCRIPT_DIR/agent-sync" ]]; then
  dirty=$(git -C "$(dirname "$SCRIPT_DIR")" status --porcelain agents 2>/dev/null | wc -l | xargs)
  if [[ "$dirty" == "0" ]]; then
    echo "[OK] agents/ committed"
  else
    echo "[--] agents/ has $dirty uncommitted change(s) — run: agent-sync"
  fi
else
  echo "[--] agent-sync not found"
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
        nix|home-manager|zsh|tmux|nvim|ripgrep|fd|fzf|direnv|claude)
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
