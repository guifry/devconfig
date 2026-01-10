{ config, pkgs, isDarwin, ... }:

{
  home.username = "guilhemforey";
  home.homeDirectory = if isDarwin then "/Users/guilhemforey" else "/home/guilhemforey";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    tmux
    vim
    git
    curl
    jq
    ripgrep
    fzf
    direnv
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      # Auto-start tmux
      if [[ -z "$TMUX" ]]; then
          tmux new-session -A -s main
      fi

      # Direnv
      eval "$(direnv hook zsh)"
      export NIX_CONFIG="warn-dirty = false"
    '';
    shellAliases = {
      loadzsh = "source ~/.zshrc";
    };
  };

  programs.tmux = {
    enable = true;
    prefix = "C-]";
    keyMode = "vi";
    mouse = true;
    extraConfig = ''
      # Pane navigation (hjkl)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
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
    userName = "Guilhem Forey";
    userEmail = ""; # Fill in
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
