# Contabo factory — reference

Last built: 2026-11-07. Verify live state before changing anything.

## What it is

An always-on Linux box for coding agents, Orca, Docker and devconfig. The Mac is the client; this VM is the factory. It is not a laptop and it is not backed up by magic — code belongs on GitHub, config belongs in devconfig, Orca state belongs in `~/.orca`, Hermes state in `~/.hermes`.

## Provider and tier

- Contabo **Cloud VPS 8**, monthly, no term.
- 8 vCPU, 24 GB RAM, 300 GB disk (290 GiB usable).
- Ubuntu **24.04.5 LTS**, kernel 6.8.0-147-generic.
- Location: see the Contabo control panel for this VPS.
- OS hostname: `vmi3733743`.
- Tailscale name: `contabo-factory`.
- 4 GB swap at `/swapfile`; timezone `Europe/London`.

## Network

| | |
|---|---|
| Public IPv4 | `5.253.235.125` |
| Public IPv6 | `2a02:c207:2373:3743::1` |
| Tailnet IPv4 | `100.109.251.16` |
| Tailnet IPv6 | `fd7a:115c:a1e0::b22a:fb11` |
| Tailscale | 1.104.5, MagicDNS short name `contabo-factory` (full domain in the admin console) |
| Tailscale SSH | **disabled** (`tailscale up --ssh=false`) so port 22 over the tailnet reaches OpenSSH |
| IPv6 | global address, but **no default IPv6 route**. IPv4 is preferred via `/etc/gai.conf` |

Tailnet owner account is in the password manager. Do not publish it here.

## Access from the Mac

Key: `~/.ssh/contabo_agent` (ed25519, no passphrase). Back it up.

`~/.ssh/config`:

```
Host contabo
  HostName 5.253.235.125
  User dev
  IdentityFile ~/.ssh/contabo_agent

Host contabo-ts
  HostName 100.109.251.16
  User dev
  IdentityFile ~/.ssh/contabo_agent
```

- `contabo` is the public route. **Dead while UFW is active.** Kept as documentation and as a break-glass reference.
- `contabo-ts` is the working route.
- Human shell: `mosh contabo-ts`.
- The `mosh` shell alias is `mosh --ssh=/usr/bin/ssh` because Nix OpenSSH does not implement Apple's `UseKeychain`, and mosh otherwise refuses to parse `~/.ssh/config`.

## Firewall

UFW is active:

- default deny incoming
- default allow outgoing
- default deny routed
- allow in on `tailscale0`
- allow `41641/udp` (Tailscale direct path)

Public SSH and public mosh are closed. `ssh contabo` and `mosh contabo` time out by design.

OpenSSH listens on `0.0.0.0:22`, but UFW only admits it on `tailscale0`. Mosh uses UDP 60000–61000; `mosh-server` binds to the address the SSH handshake reached, and over the tailnet it is admitted by `tailscale0`.

```
sudo ufw status verbose
```

Disable only from the console: `sudo ufw disable`. Re-enable with `sudo ufw enable`.

## sshd

Effective settings:

```
passwordauthentication no
permitrootlogin no
pubkeyauthentication yes
```

Files:

- `/etc/ssh/sshd_config.d/50-cloud-init.conf` — `PasswordAuthentication` edited to `no` (first value wins in OpenSSH).
- `/etc/ssh/sshd_config.d/99-dev-hardening.conf` — `PasswordAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`.

Check:

```
sudo sshd -T | grep -E '^(passwordauthentication|permitrootlogin|pubkeyauthentication)'
```

## Users and sudo

| User | Purpose | Login | Notes |
|---|---|---|---|
| `root` | break-glass only | Contabo VNC console | password in the password manager; `PermitRootLogin no` |
| `dev` | daily user and all agents | SSH key over the tailnet | uid 1001; groups `sudo`, `docker`, `users`; home `/home/dev`; shell `/home/dev/.nix-profile/bin/zsh` (added to `/etc/shells`) |
| `nixbld1-32` | Nix build users | none | created by the Nix installer |
| `tailscale`, `docker` | service users | none | created by the packages |

- `dev` password is in the password manager. Needed for interactive `sudo` if the NOPASSWD file is removed.
- `dev` SSH key: `~/.ssh/contabo_agent` on the Mac; public key in `/home/dev/.ssh/authorized_keys`.
- Temporary passwordless sudo: `/etc/sudoers.d/90-dev-provisioning` (`dev ALL=(ALL) NOPASSWD:ALL`). Remove it when unattended setup is done, or keep deliberately.
- Root SSH is disabled. Root is console-only.
- No other human accounts. Do not create one per agent; use `dev` and git worktrees.

## Installed stack

As built:

- Nix (Determinate 3.24.2) 2.35.3
- Home Manager 26.11-pre
- zsh, tmux, mosh, nvim, git, gh, gcloud, node 24, uv, mise
- Claude Code 2.1.319
- Codex CLI 0.167.0
- OpenCode 1.19.5
- Docker 29.9.3; `dev` in the `docker` group
- Tailscale 1.104.5
- devconfig extras: ripgrep, fd, fzf, direnv, lazygit, yazi, btop

Versions drift. Check with `claude --version`, `codex --version`, `opencode --version`, `docker --version`, `tailscale version`.

## devconfig

- Repo: `~/projects/devconfig`, public clone.
- Server output: `linux-x86-server`.
- `DEVCONFIG_MODE=server` is exported from `~/.zshenv`, so `devconfig switch` stays headless and does not install Ghostty or xclip.
- After a pull: `cd ~/projects/devconfig && git pull --ff-only && devconfig switch`.
- Non-interactive PATH includes `/nix/var/nix/profiles/default/bin`, `~/.nix-profile/bin`, `~/.local/bin`, `~/bin` via `programs.zsh.envExtra`. This matters for agents and Orca.
- Agent config is symlinked into the repo: `~/.claude`, `~/.codex`, `~/.config/opencode`.
- Orca hooks and the `orca-cli` skill are in the repo and symlinked.
- `~/.secrets` is a template, mode 600. Fill it; never commit it.
- `~/.gitconfig-guifry` is the personal GitHub noreply identity. `~/.gitconfig-kpler` is a placeholder; fix it before committing work repos.

## Orca

- Use `contabo-ts` as the SSH host. OpenSSH over the tailnet, key auth, port forwarding available.
- Do **not** use `contabo` (public, firewalled).
- Tailscale SSH is off on purpose: Orca's managed server needs OpenSSH port forwarding.
- Remote Orca Server (`orca serve`) is optional and not installed yet. Install after SSH is stable.
- Orca skill: `~/.agents/skills/orca-cli`.

## Provider auth

Not done at build time:

```
gh auth login
claude auth login
codex login --device-auth
opencode auth login
gcloud auth login --no-launch-browser
```

Checks:

```
gh auth status
claude auth status
codex login status
opencode auth list
```

## Break-glass: lost access

The console is independent of SSH, Tailscale and the key.

1. Contabo control panel → VPS → **VNC console**.
2. Log in as root with the password in the password manager.
3. Fix whatever is broken:
   - `sudo ufw disable`
   - `sudo tailscale logout && sudo tailscale up --ssh=false --hostname contabo-factory`
   - add a new public key to `/home/dev/.ssh/authorized_keys`
4. Re-enable UFW when done.

If the Tailscale account is lost, the VM is not lost. Create or join a new tailnet and re-auth from the console. If the Mac is lost, any device on the tailnet can SSH with the key; otherwise use the console.

The only way to truly lose the VM is: public SSH closed, Tailscale account gone, and no Contabo access. Keep the Contabo credentials and 2FA safe, and back up `~/.ssh/contabo_agent`.

## Troubleshooting

### `ssh contabo-ts` times out

1. Is Tailscale connected on the Mac? `tailscale status`, menu bar.
2. `tailscale ping contabo-factory` — direct or relay.
3. Is the VM running? Contabo panel.
4. Is UFW blocking the tailnet? Console; `sudo ufw status verbose`.
5. `sudo systemctl status tailscaled` on the VM.

### `ssh contabo` times out

Expected. Public SSH is closed. Use `contabo-ts` or the console.

### mosh: `Bad configuration option: usekeychain`

Nix OpenSSH does not support Apple's `UseKeychain`. The `mosh` alias uses `/usr/bin/ssh`. Open a new shell, or run:

```
mosh --ssh=/usr/bin/ssh contabo-ts
```

Check the server side: `ss -ulnp | grep mosh`.

### `Permission denied (publickey)`

`ssh -v contabo-ts`; check `~/.ssh/contabo_agent`, `~/.ssh/authorized_keys`, and permissions (`700` on `.ssh`, `600` on files). The console can add the key.

### Tailscale not connecting

```
sudo tailscale status
sudo systemctl status tailscaled
sudo tailscale up --ssh=false --hostname contabo-factory
```

Approve the printed URL. UFW must allow `41641/udp` and `tailscale0`.

### Anthropic API times out

The VM has a global IPv6 address but no IPv6 default route. `api.anthropic.com` has an AAAA record, so some clients try IPv6 first and hang for 10 seconds.

Check IPv4:

```
curl -4 -o /dev/null -w '%{http_code}\n' --max-time 10 https://api.anthropic.com/
```

`404` means the API is reachable. The fix applied is an IPv4 preference in `/etc/gai.conf`:

```
precedence ::ffff:0:0/96  100
```

Verify with `getent ahosts api.anthropic.com` — IPv4 should come first. `claude -p "say ok"` should reach `Not logged in · Please run /login`, not `Unable to connect`.

If a Node tool still stalls, prefix it:

```
NODE_OPTIONS=--dns-result-order=ipv4first claude
```

If IPv4 also times out, check the Contabo location against Anthropic's supported countries and test the same request from another host.

### Locked out after a UFW change

Console → `sudo ufw disable`. Inspect `sudo ufw status verbose`; re-enable with the tailnet and 41641 rules.

### Orca cannot connect

- Use `contabo-ts`, not `contabo`.
- Confirm `tailscale up --ssh=false` (Tailscale SSH breaks port forwarding).
- UFW must allow `tailscale0`.
- Check Orca's managed-server logs and version.

### devconfig switch fails

```
cd ~/projects/devconfig
git pull --ff-only
DEVCONFIG_MODE=server devconfig switch
```

If `nix` is missing, start a login shell. `devconfig doctor` for the rest. Nvim LSPs are skipped in server mode; run `devconfig nvim-setup` if wanted.

### Disk full

```
df -h /
docker system df
du -sh ~/projects/*
nix-collect-garbage -d
```

Remove old worktrees. Contabo can resize the disk; grow the partition with `growpart` and `resize2fs`.

### Cloud-init failed units

```
sudo systemctl reset-failed cloud-init.service cloud-final.service
```

Harmless on Contabo; network and SSH work.

### DNS or downloads fail

```
curl -I https://github.com
resolvectl status
```

Retry. Transient DNS failures happened during the first mise install.

### After a reboot

```
ssh contabo-ts
systemctl --failed
docker ps
tailscale status
```

## Rebuild from scratch

1. Contabo Cloud VPS 8, Ubuntu 24.04, add `~/.ssh/contabo_agent.pub` for `dev` (or root first).
2. Install Nix: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm`.
3. `curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash -s -- --mode server --yes`.
4. `sudo tailscale up --ssh=false --hostname contabo-factory`, then the UFW rules.
5. Prefer IPv4: `echo 'precedence ::ffff:0:0/96  100' | sudo tee -a /etc/gai.conf` (the VM has no IPv6 default route).
6. Docker: `curl -fsSL https://get.docker.com | sh`; `sudo usermod -aG docker dev`.
7. 4 GB swap and `Europe/London`.
8. Auth: gh, claude, codex, opencode, gcloud.
9. Orca: add `contabo-ts` as an SSH host.

## Secrets

Never commit: private keys, passwords, Tailscale auth keys, provider tokens, `~/.secrets`, `.env`. This repository is public.
