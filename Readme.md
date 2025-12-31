# Dev config

## Setup (new machine)

```bash
./setup.sh
source ~/.zshrc
```

Then follow the **GitHub CLI Setup** section below.

## Update devconfig repo

```bash
./update.sh
```

## Steps for new machines

Install:

- Brew & XCode command line tools
- Pyenv
- Docker
- Github SSH keys (see SSH config below)
- VSCode and enable Sync
- ITerm2
- NVM
- oh-my-zsh
- direnv (`brew install direnv`)
- gh CLI (`brew install gh`)
- This repository

## Secrets

Local secrets (tokens, API keys) are stored in `~/.secrets` which is sourced by `.zshrc`.
This file is NOT committed. See `.secrets.example` for template.

## GitHub CLI Setup (multi-account)

Personal account is default everywhere. Work account auto-activates in work folders.

### 1. Login to both accounts

```bash
gh auth login   # login as guifry (personal)
gh auth login   # login as gforey-ext (work)
```

### 2. Get personal token and add to ~/.secrets

```bash
gh auth switch -u guifry
gh auth token   # copy this
```

Edit `~/.secrets`:
```bash
export GH_TOKEN="ghp_your_personal_token"
```

### 3. Get work token and create work folder .envrc

```bash
gh auth switch -u gforey-ext
gh auth token   # copy this
```

Create `~/kpler/.envrc`:
```bash
export GH_TOKEN="ghp_your_work_token"
```

Then allow it:
```bash
direnv allow ~/kpler
```

### 4. Switch back to personal as default

```bash
gh auth switch -u guifry
```

### 5. Test

```bash
cd ~/projects/anything    # gh auth status → guifry
cd ~/kpler/any-repo       # gh auth status → gforey-ext
```

## SSH Config

`~/.ssh/config`:
```
Host github.com-guifry
  HostName github.com
  User git
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_ed25519_guifry

Host github.com-gforey-ext
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_kpler

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519_kpler
```

For personal repos, use: `git@github.com-guifry:guifry/repo.git`
