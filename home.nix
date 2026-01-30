{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  envUser = builtins.getEnv "USER";
  envHome = builtins.getEnv "HOME";
  username = if envUser != "" then envUser else "user";
  homeDirectory = if envHome != "" then envHome
    else if isDarwin then "/Users/${username}"
    else "/home/${username}";
in {
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    gnumake
    curl
    jq
    ripgrep
    fd
    btop
    lazygit
    gh
    mise
    neovim
    yazi
    wezterm
  ] ++ lib.optionals (!isDarwin) [
    xclip
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    sessionVariables = {
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --exclude .git";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "vi-mode" ];
    };
    initContent = ''
      eval "$(direnv hook zsh)"
      export NIX_CONFIG="warn-dirty = false"

      [[ -f ~/.secrets ]] && source ~/.secrets

      if [[ -d ~/.aliases.d ]]; then
        for f in ~/.aliases.d/*.sh(N); do
          [[ -f "$f" ]] && source "$f"
        done
      fi

      export ENABLE_LSP_TOOL=1
      export PATH="$HOME/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"

      # NVM
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # pyenv
      export PYENV_ROOT="$HOME/.pyenv"
      [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
      command -v pyenv &>/dev/null && eval "$(pyenv init - zsh)"

      # mise
      command -v mise &>/dev/null && eval "$(mise activate zsh)"

      # opencode
      export PATH="$HOME/.opencode/bin:$PATH"

      # electron-forge tabtab
      [[ -f ~/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh ]] && . ~/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh

      # Claude Code sounds
      alias sounds-on='touch ~/.claude/sounds/.enabled && echo "Sounds enabled"'
      alias sounds-off='rm -f ~/.claude/sounds/.enabled && echo "Sounds disabled"'

      alias lg='lazygit'
      alias cortex="cd ~/projects/cortex && claude --dangerously-skip-permissions 'startup'"

      # Migrated from bashrc
      alias la='ls -A'
      alias ls='ls -GFA'
      alias vi='nvim'
      alias tf='terraform'
      alias dc='docker-compose'
      alias py='python3'
      alias ns='nix-shell'
      alias activate='source ./venv/bin/activate'

      function killport () {
        lsof -ti tcp:$1 | xargs kill -9;
      }

      function reload () {
        [[ -n "$TMUX" ]] && tmux source-file ~/.config/tmux/tmux.conf
        exec zsh
      }
    '' + lib.optionalString isDarwin ''
      export PATH="/opt/homebrew/bin:$PATH"

      # Google Cloud SDK
      [[ -f ~/Downloads/google-cloud-sdk/path.zsh.inc ]] && source ~/Downloads/google-cloud-sdk/path.zsh.inc
      [[ -f ~/Downloads/google-cloud-sdk/completion.zsh.inc ]] && source ~/Downloads/google-cloud-sdk/completion.zsh.inc
    '' + lib.optionalString (!isDarwin) ''
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
    '';
  };

  programs.tmux = {
    enable = true;
    prefix = "C-]";
    keyMode = "vi";
    mouse = true;
    resizeAmount = 5;
    escapeTime = 10;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = tmux-thumbs;
        extraConfig = ''
          set -g @thumbs-key f
        '' + (if isDarwin then ''
          set -g @thumbs-command 'echo -n {} | pbcopy'
        '' else ''
          set -g @thumbs-command 'echo -n {} | xclip -selection clipboard'
        '');
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
    ];
    extraConfig = ''
      set -g renumber-windows on
      set -g set-clipboard on
      set -g allow-passthrough on

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      bind e select-layout tiled

      # Swap current window with target: prefix + S, then enter number
      bind S command-prompt -p "swap with:" "swap-window -t '%%'"

      # Insert current window at position (shifts others): prefix + I
      bind I command-prompt -p "insert at:" "run-shell 'for i in $(tmux list-windows -F \"##I\" | sort -rn); do [ $i -ge %% ] && tmux move-window -s $i -t $((i+1)); done; tmux move-window -t %%'"

      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      bind -T copy-mode-vi v send -X begin-selection
      set -g mode-style "fg=black,bg=yellow"
    '' + (if isDarwin then ''
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
      bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel "pbcopy"
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"
    '' else ''
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard"
      bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel "xclip -selection clipboard"
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "xclip -selection clipboard"
    '');
  };

  programs.git = {
    enable = true;
    ignores = [
      "Session.vim"
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];
    settings = {
      core.editor = "nvim";
      alias = {
        br = "branch";
        c = "commit";
        ca = "commit --amend";
        co = "checkout";
        cp = "cherry-pick";
        l = "log";
        pf = "push --force";
        pfl = "push --force-with-lease";
        pnew = "!git push --set-upstream origin $(git symbolic-ref --short HEAD)";
        pur = "pull --rebase";
        rb = "rebase";
        rbi = "rebase -i";
        st = "status";
        upc = "commit --amend --no-edit";
        saveb = "!git checkout -b \"save--$(git symbolic-ref --short HEAD)\"";
        delsave = "!git branch -D \"save--$(git symbolic-ref --short HEAD)\"";
      };
    };
    includes = [
      { condition = "gitdir:~/kpler/"; path = "~/.gitconfig-kpler"; }
      { condition = "gitdir:~/GDS/"; path = "~/.gitconfig-gds"; }
      { condition = "gitdir:~/projects/"; path = "~/.gitconfig-guifry"; }
      { condition = "gitdir:~/bp/"; path = "~/.gitconfig-bp"; }
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Set Bloom as default file viewer for "Reveal in Finder" actions
  # https://bloomapp.club/user-guide#restore
  home.activation.configureBloom = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    /usr/bin/defaults write -g NSFileViewer -string com.asiafu.Bloom
    if ! /usr/bin/defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -q "com.asiafu.Bloom"; then
      /usr/bin/defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType="public.folder";LSHandlerRoleAll="com.asiafu.Bloom";}'
    fi
  '');

  # Copy Mouseless config (keyboard-driven mouse control)
  # https://mouseless.click/docs/keybindings.html
  home.activation.configureMouseless = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    MOUSELESS_DIR="$HOME/Library/Containers/net.sonuscape.mouseless/Data/.mouseless/configs"
    if [ -d "$MOUSELESS_DIR" ]; then
      cp "${config.home.homeDirectory}/projects/devconfig/macos/mouseless-config.yaml" "$MOUSELESS_DIR/config.yaml"
    fi
  '');

  # Restore Homerow config (keyboard navigation)
  # https://www.homerow.app
  home.activation.configureHomerow = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${config.home.homeDirectory}/projects/devconfig/macos/homerow.plist" ]; then
      /usr/bin/defaults import com.superultra.Homerow "${config.home.homeDirectory}/projects/devconfig/macos/homerow.plist"
    fi
  '');

  # Restore Default Folder X config (enhanced file dialogs)
  # https://www.stclairsoft.com/DefaultFolderX/
  home.activation.configureDefaultFolderX = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${config.home.homeDirectory}/projects/devconfig/macos/default-folder-x.plist" ]; then
      /usr/bin/defaults import com.stclairsoft.DefaultFolderX5 "${config.home.homeDirectory}/projects/devconfig/macos/default-folder-x.plist"
    fi
  '');

  # Restore Click2Minimize config (Finder icon behaviour)
  # https://click2minimize.com
  home.activation.configureClick2Minimize = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${config.home.homeDirectory}/projects/devconfig/macos/click2minimize.plist" ]; then
      /usr/bin/defaults import com.idemfactor.Click2Minimize "${config.home.homeDirectory}/projects/devconfig/macos/click2minimize.plist"
    fi
  '');

  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;
}
