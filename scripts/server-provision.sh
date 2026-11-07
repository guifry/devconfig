#!/usr/bin/env bash
set -euo pipefail

# Idempotent system fixups for a headless devconfig server.
# Run as the agent user with sudo (NOPASSWD for unattended bootstrap).

FORCE_FIREWALL=false
SKIP_FIREWALL=false
SKIP_DOCKER=false

for arg in "$@"; do
  case "$arg" in
    --firewall) FORCE_FIREWALL=true ;;
    --no-firewall) SKIP_FIREWALL=true ;;
    --no-docker) SKIP_DOCKER=true ;;
    -h|--help)
      echo "Usage: server-provision.sh [--firewall] [--no-firewall] [--no-docker]"
      echo "  --firewall     enable UFW even if Tailscale is not connected (risky)"
      echo "  --no-firewall  never touch UFW"
      echo "  --no-docker    skip Docker installation and group membership"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [[ "$(uname)" != "Linux" ]]; then
  echo "server-provision: Linux only" >&2
  exit 1
fi

if ! sudo -n true 2>/dev/null; then
  echo "server-provision: passwordless sudo required" >&2
  echo "Add: echo '$USER ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/90-dev-provisioning" >&2
  exit 1
fi

TARGET_USER="${DEVCONFIG_USER:-}"
if [[ -z "$TARGET_USER" ]]; then
  if [[ "$(id -u)" -eq 0 ]]; then
    TARGET_USER="dev"
  else
    TARGET_USER="$USER"
  fi
fi
SERVER_TZ="${SERVER_TZ:-Europe/London}"

echo "server-provision: user=$TARGET_USER timezone=$SERVER_TZ"

# Swap: 4 GB when none exists.
if ! swapon --show | grep -q .; then
  echo "swap: creating 4G /swapfile"
  sudo fallocate -l 4G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=none
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile >/dev/null
  sudo swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
else
  echo "swap: present"
fi

sudo timedatectl set-timezone "$SERVER_TZ"
echo "timezone: $SERVER_TZ"

# Prefer IPv4 for glibc tools. Native Claude ignores this; see the runbook.
grep -q '^precedence ::ffff:0:0/96' /etc/gai.conf 2>/dev/null \
  || echo 'precedence ::ffff:0:0/96  100' | sudo tee -a /etc/gai.conf >/dev/null

# Netplan: add DNS fallbacks and make sure the IPv6 default route is applied.
NETPLAN_FILE="$(ls /etc/netplan/*.yaml 2>/dev/null | head -1 || true)"
if [[ -n "$NETPLAN_FILE" ]]; then
  if ! grep -qE '^[[:space:]]*-[[:space:]]*(1\.1\.1\.1|9\.9\.9\.9)' "$NETPLAN_FILE"; then
    echo "netplan: adding DNS fallbacks to $NETPLAN_FILE"
    sudo cp "$NETPLAN_FILE" /tmp/devconfig-netplan.bak
    sudo python3 - "$NETPLAN_FILE" <<'PY'
import re, sys
path = sys.argv[1]
lines = open(path).read().splitlines()
ns = next((i for i, l in enumerate(lines) if l.strip() == 'nameservers:'), None)
if ns is None:
    sys.exit(0)
addr = next((i for i in range(ns + 1, len(lines)) if lines[i].strip() == 'addresses:'), None)
if addr is None:
    sys.exit(0)
indent = None
end = addr
for i in range(addr + 1, len(lines)):
    m = re.match(r'^(\s*)-\s', lines[i])
    if m:
        indent = indent or m.group(1)
        end = i
    elif lines[i].strip() == '':
        continue
    else:
        break
if indent is None:
    indent = re.match(r'^(\s*)', lines[addr]).group(1) + '  '
existing = {re.sub(r'^\s*-\s*', '', l).strip() for l in lines[addr + 1:end + 1] if re.match(r'^\s*-\s', l)}
add = [ip for ip in ('1.1.1.1', '9.9.9.9') if ip not in existing]
if add:
    lines[end + 1:end + 1] = [f'{indent}- {ip}' for ip in add]
    open(path, 'w').write('\n'.join(lines) + '\n')
PY
    if ! sudo netplan generate 2>/dev/null; then
      echo "netplan: generate failed, restoring backup" >&2
      sudo cp /tmp/devconfig-netplan.bak "$NETPLAN_FILE"
    else
      sudo netplan apply
    fi
  fi
fi

if ! ip -6 route show default | grep -q .; then
  echo "ipv6: no default route, applying netplan"
  sudo netplan apply || true
fi
if ip -6 route show default | grep -q .; then
  echo "ipv6: default route present"
else
  echo "ipv6: NO default route; AAAA-only clients may hang" >&2
fi

# sshd hardening: only when the target user already has a key.
AUTH_KEYS="/home/$TARGET_USER/.ssh/authorized_keys"
if [[ -s "$AUTH_KEYS" ]]; then
  sudo tee /etc/ssh/sshd_config.d/00-dev-hardening.conf >/dev/null <<'EOF'
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
EOF
  if sudo sshd -t; then
    sudo systemctl reload ssh
    echo "sshd: key-only, root login off"
  else
    sudo rm -f /etc/ssh/sshd_config.d/00-dev-hardening.conf
    echo "sshd: config invalid, skipped" >&2
  fi
else
  echo "sshd: skipped, no authorized_keys for $TARGET_USER" >&2
fi

# Docker.
if [[ "$SKIP_DOCKER" == false ]]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker: installing"
    curl -fsSL https://get.docker.com | sudo sh
  fi
  sudo systemctl enable --now docker >/dev/null 2>&1 || true
  if id "$TARGET_USER" >/dev/null 2>&1; then
    sudo usermod -aG docker "$TARGET_USER"
  fi
  echo "docker: $(docker --version 2>/dev/null || echo installed)"
fi

# Tailscale package only. Authentication stays manual.
if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale: installing"
  curl -fsSL https://tailscale.com/install.sh | sudo sh
fi
echo "tailscale: $(tailscale version 2>/dev/null | head -1 || echo installed)"

# UFW only when Tailscale is connected, unless forced.
if [[ "$SKIP_FIREWALL" == false ]]; then
  TS_RUNNING=false
  if command -v tailscale >/dev/null 2>&1; then
    if tailscale status --json 2>/dev/null | grep -q '"BackendState":"Running"'; then
      TS_RUNNING=true
    fi
  fi
  if [[ "$FORCE_FIREWALL" == true || "$TS_RUNNING" == true ]]; then
    command -v ufw >/dev/null 2>&1 || sudo apt-get install -y ufw >/dev/null
    sudo ufw default deny incoming >/dev/null
    sudo ufw default allow outgoing >/dev/null
    sudo ufw allow in on tailscale0 >/dev/null
    sudo ufw allow 41641/udp >/dev/null
    sudo ufw --force enable >/dev/null
    echo "ufw: enabled, tailnet only"
  else
    echo "ufw: skipped, Tailscale not connected. Re-run with --firewall after auth." >&2
  fi
fi

echo "server-provision: done"
