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
    google-cloud-sdk
    mise
    neovim
    yazi
    fastfetch
    pgformatter
    postgresql
  ] ++ lib.optionals (!isDarwin) [
    ghostty
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
      if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
        tmux new-session -A -s main
      fi

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

      alias cs='claude --dangerously-skip-permissions'
      alias lg='lazygit'
      alias ff='fastfetch'
      alias treadmill='cat << "EOF"
┌──────────┬──────────┬──────────────────┬───────────────────────┐
│  Speed   │ kcal/min │ 70 min (no arms) │ 70 min (arms on desk) │
├──────────┼──────────┼──────────────────┼───────────────────────┤
│ 1.0 mph  │ 3.4      │ 241              │ ~198                  │
├──────────┼──────────┼──────────────────┼───────────────────────┤
│ 1.5 mph  │ 4.4      │ 310              │ ~254                  │
├──────────┼──────────┼──────────────────┼───────────────────────┤
│ 2.0 mph  │ 5.4      │ 378              │ ~310                  │
├──────────┼──────────┼──────────────────┼───────────────────────┤
│ 2.2 mph  │ 5.8      │ 406              │ ~333                  │
├──────────┼──────────┼──────────────────┼───────────────────────┤
│ 2.5 mph  │ 6.4      │ 448              │ ~367                  │
├──────────┼──────────┼──────────────────┼───────────────────────┤
│ 2.75 mph │ 6.9      │ 482              │ ~395                  │
├──────────┼──────────┼──────────────────┼───────────────────────┤
│ 3.0 mph  │ 7.4      │ 516              │ ~423                  │
└──────────┴──────────┴──────────────────┴───────────────────────┘
85kg, 4% incline, ACSM walking equation. Arms on desk: ~18% reduction.
EOF
'
      alias cortex="cd ~/projects/cortex && claude --dangerously-skip-permissions 'startup'"
      alias dvc="cd ~/projects/devconfig && claude --dangerously-skip-permissions --resume"

      # Migrated from bashrc
      alias la='ls -A'
      alias ls='ls -GFA'
      alias vi='nvim'
      alias tf='terraform'
      alias dc='docker-compose'
      alias py='python3'
      alias ns='nix-shell'
      alias activate='source ./venv/bin/activate'

      function y () {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      function killport () {
        lsof -ti tcp:$1 | xargs kill -9;
      }

      function reload () {
        [[ -n "$TMUX" ]] && tmux source-file ~/.config/tmux/tmux.conf
        exec zsh
      }
    '' + lib.optionalString isDarwin ''
      export PATH="/opt/homebrew/bin:$PATH"
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
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];
    extraConfig = ''
      set -g renumber-windows on
      set -g set-clipboard on
      set -g allow-passthrough on

      set -g window-style 'bg=#1a1b26'
      set -g window-active-style 'bg=#24283b'

      # tokyonight storm palette
      set -g status-position top
      set -g status-style "bg=#1f2335,fg=#a9b1d6"
      set -g status-left "#[fg=#7aa2f7,bold] #S #[default]"
      set -g status-left-length 20
      set -g status-right "#[fg=#565f89]%H:%M"
      set -g status-right-length 10
      set -g window-status-format "#[fg=#565f89] #I:#W"
      set -g window-status-current-format "#[fg=#7aa2f7,bold] #I:#W"
      set -g window-status-separator ""
      set -g pane-border-style "fg=#1f2335"
      set -g pane-active-border-style "fg=#3b4261"
      set -g message-style "bg=#1f2335,fg=#7aa2f7"

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

      bind c new-window -c "#{pane_current_path}"
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

  xdg.configFile."nvim/init.lua".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/nvim/init.lua";
  xdg.configFile."aerospace/aerospace.toml".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/aerospace.toml";
  xdg.configFile."ghostty/config".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/ghostty.config";

  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/claude/CLAUDE.md";
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/claude/settings.json";
  home.file.".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/claude/commands";
  home.file.".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/claude/skills";
  home.file.".claude/hooks".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/projects/devconfig/claude/hooks";

  home.file."bin/ax" = { source = ./scripts/ax; executable = true; };
  home.file."bin/rx" = { source = ./scripts/rx; executable = true; };
  home.file."bin/tx" = { source = ./scripts/tx; executable = true; };
  home.file."bin/vx" = { source = ./scripts/vx; executable = true; };
  home.file."bin/playwright-auth" = { source = ./scripts/playwright-auth; executable = true; };
  home.file."bin/create_script" = { source = ./scripts/create_script; executable = true; };
  home.file."bin/edscript" = { source = ./scripts/edscript; executable = true; };
}
