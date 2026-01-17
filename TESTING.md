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
