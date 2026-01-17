if [[ -z "$TMUX" ]]; then
  tmux new-session -A -s main
fi

[[ -f ~/.secrets ]] && source ~/.secrets

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

export ENABLE_LSP_TOOL=1

eval "$(direnv hook zsh)"
export NIX_CONFIG="warn-dirty = false"

for f in ~/.aliases.d/*.sh; do
  [[ -f "$f" ]] && source "$f"
done

if [[ "$OSTYPE" == darwin* ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
  [[ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]] && . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
  [[ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]] && . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"
fi

if [[ "$OSTYPE" == linux* ]]; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv &>/dev/null && eval "$(pyenv init - zsh)"

command -v mise &>/dev/null && eval "$(mise activate zsh)"
