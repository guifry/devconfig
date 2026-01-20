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

      if [[ -d ~/.aliases.d ]]; then
        for f in ~/.aliases.d/*.sh(N); do
          [[ -f "$f" ]] && source "$f"
        done
      fi

      export ENABLE_LSP_TOOL=1
      export PATH="$HOME/bin:$PATH"

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

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

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

  programs.vim = {
    enable = true;
    settings = {
      number = true;
      relativenumber = true;
    };
    extraConfig = ''
      syntax on
      set nocompatible
      filetype plugin indent on

      set belloff=all
      set tabstop=4
      set softtabstop=4
      set shiftwidth=4
      set expandtab
      set smartindent
      set wrap
      set smartcase
      set noswapfile
      set nobackup
      set undodir=~/.vim/undodir
      set undofile
      set incsearch
      set ttimeoutlen=80
      set colorcolumn=80
      set clipboard=unnamed
      set statusline=%f\ %m\ %=\ %l:%c
      highlight ColorColumn ctermbg=0 guibg=lightgrey

      " Yankstack paste navigation
      nmap <M-p> <Plug>yankstack_substitute_older_paste
      nmap <M-n> <Plug>yankstack_substitute_newer_paste

      " Keep selection when pasting in visual mode
      xnoremap p pgvy

      " vim-plug
      call plug#begin('~/.vim/plugged')

      Plug 'morhetz/gruvbox'
      Plug 'jremmen/vim-ripgrep'
      Plug 'tpope/vim-fugitive'
      Plug 'leafgarland/typescript-vim'
      Plug 'vim-utils/vim-man'
      Plug 'git@github.com:kien/ctrlp.vim.git'
      Plug 'neoclide/coc.nvim', {'branch': 'release'}
      Plug 'mbbill/undotree'
      Plug 'JamshedVesuna/vim-markdown-preview'
      Plug 'yuezk/vim-js'
      Plug 'HerringtonDarkholme/yats.vim'
      Plug 'maxmellon/vim-jsx-pretty'
      Plug 'maxbrunsfeld/vim-yankstack'
      Plug 'preservim/nerdtree'

      call plug#end()

      " NERDTree
      nnoremap <leader>n :NERDTreeToggle<CR>
      nnoremap <leader>f :NERDTreeFind<CR>
      let NERDTreeShowHidden=1
    '';
  };

  programs.git = {
    enable = true;
    settings = {
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

  home.activation.createVimUndoDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ~/.vim/undodir
  '';
}
