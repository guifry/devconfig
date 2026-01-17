[[ -f ~/kpler/.envrc ]] && source ~/kpler/.envrc

fst() {
  local wt_dir=$(~/bin/fst "$@")
  [[ -n "$wt_dir" && -d "$wt_dir" ]] && cd "$wt_dir"
}
