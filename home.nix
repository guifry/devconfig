{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  envUser = builtins.getEnv "USER";
  envHome = builtins.getEnv "HOME";
  username = if envUser != "" then envUser else "user";
  homeDirectory = if envHome != "" then envHome
    else if isDarwin then "/Users/${username}"
    else "/home/${username}";
  repoDir = "${homeDirectory}/projects/devconfig";
  repoFile = path: config.lib.file.mkOutOfStoreSymlink "${repoDir}/${path}";
  agentFile = path: repoFile "agents/${path}";
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
    (pkgs.btop.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or []) ++ [ "-DBTOP_GPU=OFF" ];
    }))
    lazygit
    gh
    google-cloud-sdk
    mise
    neovim
    yazi
    fastfetch
    pgformatter
    postgresql
    rainfrog
    lazydocker
    mitmproxy
    glow
    imagemagick
    mermaid-cli
    posting
    prettierd
    # node + npm. Needed for claude-code-acp (codecompanion's Claude adapter) and
    # any npx-based MCP server. nvm is deliberately NOT used — `mise` is already
    # here and manages per-project node versions the same way.
    nodejs
  ] ++ lib.optionals (!isDarwin) [
    ghostty
    xclip
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 50000;
      save = 50000;
      share = true;           # share between sessions immediately
      ignoreDups = true;
      ignoreSpace = true;     # commands starting with space not saved
      extended = true;        # save timestamps
    };
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
      # Source nix profile PATH — /etc/zshenv only does this on SSH
      if [ -z "''${__ETC_PROFILE_NIX_SOURCED:-}" ] && [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi

      if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
        tmux new-session -A -s main
      fi

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

      # Auto-activate poetry venv on cd. Needed because:
      # - direnv requires explicit .envrc per project (security by design)
      # - poetry shell is slow and doesn't set VIRTUAL_ENV properly
      # - basedpyright LSP reads VIRTUAL_ENV to find packages
      autoload -U add-zsh-hook
      _auto_poetry_venv() {
        if [[ -f pyproject.toml ]] && command -v poetry &>/dev/null; then
          local venv=$(poetry env info -p 2>/dev/null)
          if [[ -n "$venv" && -d "$venv" ]]; then
            export VIRTUAL_ENV="$venv"
            export PATH="$venv/bin:$PATH"
          fi
        fi
      }
      add-zsh-hook chpwd _auto_poetry_venv
      _auto_poetry_venv

      # mise
      command -v mise &>/dev/null && eval "$(mise activate zsh)"

      # opencode
      export PATH="$HOME/.opencode/bin:$PATH"
      export OPENCODE_EXPERIMENTAL=1

      # electron-forge tabtab
      [[ -f ~/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh ]] && . ~/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh

      # Claude Code sounds
      alias sounds-on='touch ~/.claude/sounds/.enabled && echo "Sounds enabled"'
      alias sounds-off='rm -f ~/.claude/sounds/.enabled && echo "Sounds disabled"'

      alias cs='claude --dangerously-skip-permissions'
      alias oc='opencode'
      alias ocs='opencode --dangerously-skip-permissions'
      alias claude-status='open https://status.claude.com/'
      alias go60='open https://my.moergo.com/go60/#/layout/go60-macos'
      alias lg='lazygit'
      alias ld='lazydocker'
      alias mp='mitmproxy'
      alias cal='chrome-kpler-calendar'
      alias f='fzf'
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
          unbind S
          set -g @resurrect-save 'S'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
      {
        plugin = fzf-tmux-url;
        extraConfig = ''
          set -g @fzf-url-bind 'u'
        '';
      }
    ];
    extraConfig = ''
      set -g renumber-windows on
      set -g automatic-rename off
      set-hook -g pane-focus-in "run-shell 'tmux-smart-rename'"
      set-hook -g window-pane-changed "run-shell 'tmux-smart-rename'"
      set -g set-clipboard on
      set -g allow-passthrough on
      set -g display-panes-time 3000

      set -g window-style 'bg=#1a1b26'
      set -g window-active-style 'bg=#24283b'

      # tokyonight storm palette
      set -g status-position top
      set -g status-style "bg=#1f2335,fg=#a9b1d6"
      set -g status-left "#[fg=#7aa2f7,bold] #S #[default]"
      set -g status-left-length 20
      set -g status-right "#[fg=#565f89]%H:%M"
      set -g status-right-length 10
      set -g window-status-format "#[bg=#2c2e3b,fg=#565f89] #I:#W "
      set -g window-status-current-format "#[bg=#ff9e64,fg=#1f2335,bold] #I:#W "
      set -g window-status-separator " "
      set -g pane-border-lines heavy
      set -g pane-border-style "fg=#1f2335"
      set -g pane-active-border-style "fg=#f7768e"
      set -g pane-border-status top
      set -g pane-border-format " #{?@label,#{@label},#{pane_index}} "
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

      # Rename window with empty prompt
      bind , command-prompt -p "(rename-window)" "rename-window '%%'"

      bind T command-prompt -p "pane label:" "set -p @label '%%'"
      bind t set -p @label ""

      # Swap current window with target: prefix + W, then enter number
      bind W command-prompt -p "swap with:" "swap-window -t '%%'"

      # Insert current window at position (shifts others): prefix + I
      bind I command-prompt -p "insert at:" "run-shell 'for i in $(tmux list-windows -F \"##I\" | sort -rn); do [ $i -ge %% ] && tmux move-window -s $i -t $((i+1)); done; tmux move-window -t %%'"

      # Scrollback navigation: jump between prompts in copy mode.
      # prefix+/ = Claude Code user messages (❯)
      # prefix+? = Claude Code responses (⏺)
      # prefix+. = shell prompts (➜)
      # Then n/N to repeat whichever search was last used.
      bind / copy-mode \; send-keys -X search-backward "❯"
      bind ? copy-mode \; send-keys -X search-backward "⏺"
      bind . copy-mode \; send-keys -X search-backward "➜"
      # Yank Claude's last response to system clipboard
      bind y run-shell "tmux-yank-claude"

      bind c new-window -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      bind [ copy-mode \; send-keys -X top-line
      bind -T copy-mode-vi v send -X begin-selection
      set -g mode-style "fg=black,bg=yellow"
    '' + ''
      bind -T copy-mode-vi y send -X copy-pipe-no-clear
      bind -T copy-mode-vi Enter send -X copy-pipe-no-clear
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-no-clear
    '';
  };

  programs.git = {
    enable = true;
    ignores = [
      "Session.vim"
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];
    settings = {
      # HTTPS credentials come from gh. `!/usr/bin/env gh ...` only works when gh is
      # already on PATH — true in an interactive shell, false for scripts, editors,
      # cron and coding agents, which then fail with "could not read Username".
      # Put the nix profile on PATH inside the helper so it works everywhere.
      credential."https://github.com".helper =
        "!f() { PATH=\"$HOME/.nix-profile/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH\"; gh auth git-credential \"$@\"; }; f";
      core.editor = "nvim";
      # Never guess an author from $USER@$HOSTNAME. Without this, a repo that matches
      # no include commits silently as guilhem@Guilhems-MacBook-Pro.local — succeeds,
      # but links to no GitHub account. With it, git errors and you fix the mapping.
      user.useConfigOnly = true;
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
    # Identity is selected automatically, never switched by hand. Two layers, and
    # ORDER MATTERS — git applies includes in order, last match wins.
    #
    #   1. gitdir:   by location. Covers a fresh `git init` that has no remote yet.
    #   2. hasconfig: by remote URL. Wins over location, so a work repo cloned into
    #      the wrong folder still gets the work identity. This is the guarantee that
    #      personal commits never land on Kpler and vice versa.
    #
    # Paired with user.useConfigOnly below: if nothing matches, git REFUSES to commit
    # rather than inventing an address from the hostname.
    includes = [
      { condition = "gitdir:~/kpler/"; path = "~/.gitconfig-kpler"; }
      { condition = "gitdir:~/GDS/"; path = "~/.gitconfig-gds"; }
      { condition = "gitdir:~/projects/"; path = "~/.gitconfig-guifry"; }
      { condition = "gitdir:~/bp/"; path = "~/.gitconfig-bp"; }

      # Work — by remote
      { condition = "hasconfig:remote.*.url:git@github.com-gforey-ext:*/**"; path = "~/.gitconfig-kpler"; }
      { condition = "hasconfig:remote.*.url:git@github.com:Kpler/**"; path = "~/.gitconfig-kpler"; }
      { condition = "hasconfig:remote.*.url:https://github.com/Kpler/**"; path = "~/.gitconfig-kpler"; }

      # Personal — by remote
      { condition = "hasconfig:remote.*.url:git@github.com-guifry:*/**"; path = "~/.gitconfig-guifry"; }
      { condition = "hasconfig:remote.*.url:git@github.com:guifry/**"; path = "~/.gitconfig-guifry"; }
      { condition = "hasconfig:remote.*.url:https://github.com/guifry/**"; path = "~/.gitconfig-guifry"; }
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      source_up 2>/dev/null || true

      layout_poetry() {
        if [[ ! -f pyproject.toml ]]; then
          log_error 'No pyproject.toml found'
          return 1
        fi
        local venv
        venv=$(poetry env info -p 2>/dev/null)
        if [[ -z "$venv" || ! -d "$venv" ]]; then
          poetry install
          venv=$(poetry env info -p)
        fi
        export VIRTUAL_ENV="$venv"
        export PATH="$venv/bin:$PATH"
      }
    '';
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
      cp "${repoDir}/macos/mouseless-config.yaml" "$MOUSELESS_DIR/config.yaml"
    fi
  '');

  # Restore Homerow config (keyboard navigation)
  # https://www.homerow.app
  home.activation.configureHomerow = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${repoDir}/macos/homerow.plist" ]; then
      /usr/bin/defaults import com.superultra.Homerow "${repoDir}/macos/homerow.plist"
    fi
  '');

  # Restore Default Folder X config (enhanced file dialogs)
  # https://www.stclairsoft.com/DefaultFolderX/
  home.activation.configureDefaultFolderX = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${repoDir}/macos/default-folder-x.plist" ]; then
      /usr/bin/defaults import com.stclairsoft.DefaultFolderX5 "${repoDir}/macos/default-folder-x.plist"
    fi
  '');

  # Restore Click2Minimize config (Finder icon behaviour)
  # https://click2minimize.com
  home.activation.configureClick2Minimize = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${repoDir}/macos/click2minimize.plist" ]; then
      /usr/bin/defaults import com.idemfactor.Click2Minimize "${repoDir}/macos/click2minimize.plist"
    fi
  '');

  # Key repeat. NOTE: these only take effect for an app when it next launches, and
  # fully only after a logout — macOS caches NSGlobalDomain per process at startup.
  # `devconfig switch` prints a reminder when it changes them.
  #
  # KeyRepeat 1        = fastest repeat (15ms). Below the System Settings minimum.
  # InitialKeyRepeat 12 = 180ms before repeat starts.
  # ApplePressAndHoldEnabled false = holding a key repeats it instead of showing the
  #   accent picker. Without this, held keys do nothing in some apps.
  home.activation.configureKeyboard = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 1
    /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 12
    /usr/bin/defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  '');

  xdg.configFile."nvim/init.lua".source = repoFile "nvim/init.lua";
  xdg.configFile."aerospace/aerospace.toml".source = repoFile "aerospace.toml";
  xdg.configFile."ghostty/config".source = repoFile "ghostty.config";
  xdg.configFile."lazygit/config.yml".source = repoFile "lazygit.yml";
  # Agent config. One shared source of instructions/commands/skills, fanned out to
  # every agent's expected location. Agent-specific config stays in its own dir.
  #
  # Skills auto-trigger on their `description` in Claude Code only; elsewhere they
  # are readable prompt files you invoke explicitly. opencode/codex paths are
  # unverified — see agents/{opencode,codex}/README.md.
  home.file.".claude/CLAUDE.md".source = agentFile "shared/instructions.md";
  home.file.".claude/commands".source = agentFile "shared/commands";
  home.file.".claude/skills".source = agentFile "shared/skills";
  home.file.".claude/settings.json".source = agentFile "claude/settings.json";
  home.file.".claude/hooks".source = agentFile "claude/hooks";

  xdg.configFile."opencode/opencode.json".source = agentFile "opencode/opencode.json";
  xdg.configFile."opencode/AGENTS.md".source = agentFile "shared/instructions.md";
  xdg.configFile."opencode/command".source = agentFile "shared/commands";
  xdg.configFile."opencode/skills".source = agentFile "shared/skills";

  home.file.".codex/AGENTS.md".source = agentFile "shared/instructions.md";
  home.file.".codex/prompts".source = agentFile "shared/commands";
  home.file.".codex/skills".source = agentFile "shared/skills";

  home.file."bin/ax" = { source = ./scripts/ax; executable = true; };
  home.file."bin/rx" = { source = ./scripts/rx; executable = true; };
  home.file."bin/ox" = { source = ./scripts/ox; executable = true; };
  home.file."bin/tx" = { source = ./scripts/tx; executable = true; };
  home.file."bin/xx" = { source = ./scripts/xx; executable = true; };
  home.file."bin/vx" = { source = ./scripts/vx; executable = true; };
  home.file."bin/create_script" = { source = ./scripts/create_script; executable = true; };
  home.file."bin/edscript" = { source = ./scripts/edscript; executable = true; };
  home.file."bin/aerospace-reorganise" = { source = ./scripts/aerospace-reorganise; executable = true; };
  home.file."bin/tmux-smart-rename" = { source = ./scripts/tmux-smart-rename; executable = true; };
  home.file."bin/chrome-kpler-route" = { source = ./scripts/chrome-kpler-route; executable = true; };
  home.file."bin/chrome-kpler-calendar" = { source = ./scripts/chrome-kpler-calendar; executable = true; };
  home.file."bin/aerospace-swap-center" = { source = ./scripts/aerospace-swap-center; executable = true; };
  home.file."bin/tmux-yank-claude" = { source = ./scripts/tmux-yank-claude; executable = true; };
  home.file."bin/devconfig" = { source = ./scripts/devconfig-cli.sh; executable = true; };
  home.file."bin/dcli" = { source = ./scripts/dcli; executable = true; };
  home.file."bin/agent-sync" = { source = ./scripts/agent-sync; executable = true; };
  home.file."bin/git-identity-test" = { source = ./scripts/git-identity-test; executable = true; };
  home.file.".secrets.example" = { source = ./secrets.example; };
}
