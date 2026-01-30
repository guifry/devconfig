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
  ] ++ lib.optionals (!isDarwin) [
    xclip
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    sessionVariables = {
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --exclude .git";
      EDITOR = "vim";
      VISUAL = "vim";
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
      alias vi='vim'
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
      set scrolloff=999
      set clipboard=unnamed
      set wildmenu
      set wildmode=full
      set pastetoggle=<F2>
      set statusline=%f\ %m\ %=\ %l:%c
      highlight ColorColumn ctermbg=0 guibg=lightgrey

      " Bracketed paste fix for tmux
      if !has('gui_running') && &term =~ '^\%(screen\|tmux\)'
        let &t_BE = "\<Esc>[?2004h"
        let &t_BD = "\<Esc>[?2004l"
        let &t_PS = "\<Esc>[200~"
        let &t_PE = "\<Esc>[201~"
      endif

      " Ergonomics
      nnoremap ; :
      nnoremap : ;
      inoremap jj <Esc>

      " Keep selection when pasting in visual mode
      xnoremap p pgvy

      " vim-plug
      call plug#begin('~/.vim/plugged')

      Plug 'morhetz/gruvbox'
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
      Plug 'preservim/nerdtree'
      Plug 'numEricL/nerdtree-live-preview'
      Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
      Plug 'junegunn/fzf.vim'
      Plug 'tpope/vim-obsession'
      Plug 'tpope/vim-commentary'
      Plug 'ojroques/vim-oscyank'

      call plug#end()

      " OSC52 clipboard (yank to system clipboard through tmux)
      autocmd TextYankPost * if v:event.operator is 'y' | call OSCYank(getreg('"')) | endif

      set background=dark
      set termguicolors
      colorscheme gruvbox

      let g:coc_global_extensions = ['coc-pyright', 'coc-tsserver', 'coc-json']

      " coc.nvim
      nmap <silent> gd <Plug>(coc-definition)
      nmap <silent> gr <Plug>(coc-references)
      nmap <silent> gy <Plug>(coc-type-definition)
      nmap <silent> gi <Plug>(coc-implementation)
      nmap <silent> K :call CocAction('doHover')<CR>
      nmap <silent> <leader>rn <Plug>(coc-rename)
      nmap <silent> <leader>o :CocOutline<CR>
      nmap <silent> <leader>u :UndotreeToggle<CR>

      " fzf
      nnoremap <C-p> :Files<CR>
      nnoremap <leader>b :Buffers<CR>
      nnoremap <leader>rg :Rg<CR>
      let g:fzf_action = { 'ctrl-t': 'tab split', 'ctrl-s': 'split', 'ctrl-v': 'vsplit' }

      " Sessions
      nnoremap <leader>ss :Obsession<CR>
      nnoremap <leader>sr :source Session.vim<CR>

      " NERDTree
      nnoremap <leader>n :NERDTreeToggle<CR>
      nnoremap <leader>f :NERDTreeFind<CR>
      let NERDTreeShowHidden=1
      let NERDTreeMapOpenVSplit='v'
      let NERDTreeMapOpenSplit='s'
    '' + (if isDarwin then ''
      nnoremap <leader>p :r !pbpaste<CR>
    '' else ''
      nnoremap <leader>p :r !xclip -selection clipboard -o<CR>
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
      core.editor = "vim";
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

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;
}
