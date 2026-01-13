#!/bin/bash

# Updates config files with latest local changes
cp ~/.bashrc ~/.zshrc ~/.vimrc ~/.tmux.conf .
cp ~/Library/Preferences/com.googlecode.iterm2.plist ./iterm2/
cp ~/bin/* ./scripts/ 2>/dev/null || true

