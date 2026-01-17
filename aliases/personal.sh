fst() {
  local wt_dir=$(~/bin/fst "$@")
  [[ -n "$wt_dir" && -d "$wt_dir" ]] && cd "$wt_dir"
}

alias loadzsh='source ~/.zshrc'
