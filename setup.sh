#!/bin/bash

# Setup devconfig on a new machine
# Copies config files to home directory

echo "Setting up devconfig..."

# Copy rc files
cp .bashrc ~/.bashrc
cp .zshrc ~/.zshrc
cp .vimrc ~/.vimrc
cp .tmux.conf ~/.tmux.conf

# Iterm hotkey config
cp ~/devconfig/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/

# Setup secrets file (only if doesn't exist)
if [[ ! -f ~/.secrets ]]; then
    cp .secrets.example ~/.secrets
    echo "Created ~/.secrets from template - please fill in your tokens"
else
    echo "~/.secrets already exists, skipping"
fi

# Setup direnvrc for parent .envrc inheritance
mkdir -p ~/.config/direnv
if ! grep -q "source_up" ~/.config/direnv/direnvrc 2>/dev/null; then
    echo 'source_up 2>/dev/null || true' >> ~/.config/direnv/direnvrc
    echo "Added source_up to direnvrc"
fi

# Create bin directory and copy scripts
mkdir -p ~/bin
cp scripts/* ~/bin/ 2>/dev/null || true
ln -sf ~/projects/devconfig/workspaces/kpler/create-fullstack-wt.py ~/bin/fst

echo ""
echo "Done! Next steps:"
echo "  1. Run 'source ~/.zshrc' to reload"
echo "  2. Edit ~/.secrets with your tokens (see Readme for gh CLI setup)"
