unalias chartering-fix chartering-lint chartering-format chartering-precommit 2>/dev/null

chartering-fix() {
  local root=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$root" ]] && echo "Not in a git repo" && return 1
  (cd "$root/apps/terminal" && pnpm exec eslint src/domains/chartering --ext .ts,.vue --fix --quiet)
}

chartering-precommit() {
  local root=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$root" ]] && echo "Not in a git repo" && return 1
  (cd "$root" && pre-commit run --files apps/terminal/src/domains/chartering/**/*.ts apps/terminal/src/domains/chartering/**/*.vue)
}

alias lint-webapp='pnpm eslint apps/terminal/src/domains/chartering --ext .ts,.vue --fix'
