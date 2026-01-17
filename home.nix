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
    fzf
    btop
  ] ++ lib.optionals (!isDarwin) [
    xclip
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };
    initContent = ''
      if [[ -z "$TMUX" ]]; then
        tmux new-session -A -s main
      fi

      eval "$(direnv hook zsh)"
      export NIX_CONFIG="warn-dirty = false"

      [[ -f ~/.secrets ]] && source ~/.secrets

      for f in ~/.aliases.d/*.sh; do
        [[ -f "$f" ]] && source "$f"
      done

      export ENABLE_LSP_TOOL=1
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
    extraConfig = ''
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      bind -T copy-mode-vi v send -X begin-selection
      set -g mode-style "fg=black,bg=yellow"
    '' + (if isDarwin then ''
      bind -T copy-mode-vi y send -X copy-pipe "pbcopy"
    '' else ''
      bind -T copy-mode-vi y send -X copy-pipe "xclip -selection clipboard"
    '');
  };

  programs.vim = {
    enable = true;
    settings = {
      number = true;
      relativenumber = true;
    };
    extraConfig = ''
      set nocompatible
      filetype plugin indent on
      syntax enable
      set tabstop=4
      set softtabstop=4
      set shiftwidth=4
      set expandtab
      set smartindent
      set nowrap
      set smartcase
      set noswapfile
      set nobackup
      set undodir=~/.vim/undodir
      set undofile
      set incsearch
      set colorcolumn=80
      set clipboard=unnamed
      set statusline=%f\ %m\ %=\ %l:%c
      highlight ColorColumn ctermbg=0 guibg=lightgrey
      xnoremap p pgvy
    '';
  };

  programs.git = {
    enable = true;
    aliases = {
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.activation.createVimUndoDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ~/.vim/undodir
  '';
}
