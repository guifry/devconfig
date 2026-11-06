# Testing

## Local (macOS)

Test the curl command directly:
```bash
curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

Or test from local repo:
```bash
./bootstrap.sh
```

## Docker (Linux)

The curl pipe doesn't work in a single `docker run` command due to TTY limitations. Use two-step approach:

```bash
# Start container interactively
docker run -it --rm ubuntu:22.04 bash

# Inside container:
apt update && apt install -y curl git
curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

This simulates real usage: SSH into server, paste curl command.

### Other distros

**Fedora:**
```bash
docker run -it --rm fedora:latest bash
# then: curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

**Alpine:**
```bash
docker run -it --rm alpine:latest sh
# then: apk add curl bash git && curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

**Debian:**
```bash
docker run -it --rm debian:latest bash
# then: apt update && apt install -y curl git && curl -fsSL https://raw.githubusercontent.com/guifry/devconfig/master/bootstrap.sh | bash
```

## What to verify

- [ ] Prompts for light/full choice
- [ ] Prompts for alias categories
- [ ] Nix installs successfully
- [ ] home-manager runs without errors
- [ ] `zsh`, `tmux`, `vim`, `rg` available after setup
- [ ] Restart shell or `source ~/.zshrc` works

## Server mode (Linux)

```bash
docker run -it --rm -v "$PWD:/src" ubuntu:24.04 bash
# inside the container, as root:
apt update && apt install -y curl git sudo
useradd -m -s /bin/bash dev
echo 'dev ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
su - dev
cd /src
DEVCONFIG_PATH=/src ALIAS_CATEGORIES="1 2 4" ./bootstrap.sh --local --mode server --yes
```

Server mode checklist:

- [ ] `ghostty` is **not** installed
- [ ] `xclip` is **not** installed
- [ ] `pbcopy` / `pbpaste` aliases are absent
- [ ] `mosh` is installed
- [ ] `work` alias exists (`zsh -ic 'alias work'`)
- [ ] tmux thumbs uses `tmux set-buffer`, not `xclip`
- [ ] `~/.aliases.d/macos-apps.sh` is absent
- [ ] `git commit` works after `git-identity-setup`
- [ ] `nvim` LSP setup was skipped (no `claude-code-acp` unless `--with-nvim`)
