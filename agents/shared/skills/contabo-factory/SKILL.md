---
name: contabo-factory
description: Operate and troubleshoot the Contabo factory VM (contabo-factory) — SSH and mosh over Tailscale, UFW lockout, sshd, Docker, Nix/devconfig, and Orca. Use when the user mentions Contabo, contabo-ts, the factory VM, Tailscale on that server, cannot SSH, locked out, UFW, or asks about that host.
---

# Contabo factory

Read `REFERENCE.md` in this skill before changing anything on the host.

- Human shell: `mosh contabo-ts`
- SSH: `ssh contabo-ts` — OpenSSH over Tailscale, key auth
- Public `contabo` is firewalled off. Do not re-enable it without the console.
- Break-glass: Contabo control panel → VPS → VNC console → root.

Never put passwords, private keys, or tokens in this repo.
