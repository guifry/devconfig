#!/usr/bin/env bash
# Shared destructive-command guard for Claude Code, opencode and Codex.
#
#   check-command.sh "<command>"        exit 0 = allow
#   echo "<cmd>" | check-command.sh     exit 1 = block, reason on stdout
#   check-command.sh --selftest         run the assertion table
#
# Agent adapters translate the exit code into whatever their host expects; this
# script knows nothing about any particular agent.
#
# Scope: things that are unrecoverable or that destroy shared history. It is a
# guard against accidents, not a security boundary — an agent determined to
# evade it can (cd into a directory first, base64 a payload, write a script and
# run it). The value is catching the plausible-looking one-liner.

set -uo pipefail

GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_FILE="$GUARD_DIR/dangerous-patterns.txt"
ESCAPE_HATCH="${XDG_CONFIG_HOME:-$HOME/.config}/devconfig/guard-off"

# Recursive rm targeting any of these is blocked. Bare `/` and anything under
# the home directory included, per the strict setting — `rm -rf ~/proj/foo` is
# blocked, `rm -rf ./foo` and `rm -rf /tmp/foo` are not.
# Paths that make up the guard itself. Writing to any of them, or running
# `guard off`, is refused before the escape hatch is consulted.
GUARD_PATHS='(devconfig/agents/shared/guard|devconfig/scripts/(guard|codex-guard)|devconfig/agents/(claude/hooks|codex|opencode/plugin)|config/devconfig/guard-off|bin/(guard|codex-guard)|claude/hooks/block-dangerous|opencode/plugin/guard)'
INTEGRITY_WRITE="(^|[[:space:];&|])(sudo[[:space:]]+)?(rm|mv|cp|ln|chmod|chown|truncate|shred|touch|tee|dd|install)[[:space:]][^;&|]*$GUARD_PATHS"
INTEGRITY_REDIRECT="(>|>>)[[:space:]]*[^;&|]*$GUARD_PATHS"
INTEGRITY_SED="(sed|perl|awk)[[:space:]]+-[a-zA-Z]*i[^;&|]*$GUARD_PATHS"
INTEGRITY_DISARM='(^|[[:space:];&|])guard[[:space:]]+off([[:space:]]|$)'

PROTECTED_PREFIXES=(
    '/' '/*' '~' '~/' '$HOME' '${HOME}'
    '/usr' '/etc' '/var' '/bin' '/sbin' '/opt' '/dev' '/private'
    '/System' '/Applications' '/Library' '/Volumes' '/nix' '/home' '/Users'
)

block() {
    printf '%s\n' "$1"
    exit 1
}

# Strip wrappers that would hide the real command from a `^`-anchored pattern:
# sudo, doas, env assignments, `command`/`builtin`, and an absolute directory on
# the binary itself (/bin/rm -> rm).
normalise() {
    local seg="$1"
    seg="${seg#"${seg%%[![:space:]]*}"}"
    seg="${seg%"${seg##*[![:space:]]}"}"
    while true; do
        case "$seg" in
            sudo\ *|doas\ *)          seg="${seg#* }" ;;
            sudo\ -*\ *|doas\ -*\ *)  seg="${seg#* }" ;;
            command\ *|builtin\ *)    seg="${seg#* }" ;;
            env\ *)                   seg="${seg#* }" ;;
            nohup\ *|nice\ *|time\ *) seg="${seg#* }" ;;
            [A-Za-z_]*=*\ *)          seg="${seg#* }" ;;
            /*/*)                     seg="${seg##*/}" ;;
            *) break ;;
        esac
        seg="${seg#"${seg%%[![:space:]]*}"}"
    done
    printf '%s' "$seg"
}

# Split on shell separators so `foo && rm -rf ~` is seen as its own command.
# Quoted separators split too; over-matching is the safe direction here.
# The trailing newline matters: `while read` drops an unterminated final line.
split_segments() {
    printf '%s\n' "$1" | tr '\n' ';' | sed 's/&&/;/g; s/||/;/g; s/|/;/g' | tr ';' '\n'
}

# Recursive rm has to be detected in code, not regex: -rf, -fr, -r -f, -R and
# --recursive are all the same thing and flag order is free.
check_rm() {
    local seg="$1" word recursive=0 target prefix first=1
    local -a words targets

    words=()
    targets=()
    read -ra words <<<"$seg"
    [[ ${#words[@]} -gt 0 ]] || return 0
    [[ ${words[0]} == "rm" ]] || return 0

    for word in "${words[@]}"; do
        if [[ $first -eq 1 ]]; then first=0; continue; fi
        case "$word" in
            --recursive|--recursive=*) recursive=1 ;;
            --*) ;;
            -*) [[ $word == *[rR]* ]] && recursive=1 ;;
            *) targets[${#targets[@]}]="$word" ;;
        esac
    done
    [[ $recursive -eq 1 ]] || return 0
    [[ ${#targets[@]} -gt 0 ]] || return 0

    for target in "${targets[@]}"; do
        [[ -n $target ]] || continue
        target="${target%\"}"; target="${target#\"}"
        target="${target%\'}"; target="${target#\'}"
        target="${target%/}"
        [[ -n $target ]] || target="/"
        for prefix in "${PROTECTED_PREFIXES[@]}"; do
            if [[ $target == "$prefix" || $target == "$prefix"/* ]]; then
                block "recursive rm targeting a protected path ($target)"
            fi
        done
    done
    return 0
}

check_patterns() {
    local haystack="$1" line regex reason
    while IFS=$'\t' read -r regex reason; do
        [[ -z $regex || $regex == \#* ]] && continue
        if [[ $haystack =~ $regex ]]; then
            block "${reason:-matched a blocked pattern}"
        fi
    done <"$PATTERNS_FILE"
}

# `bash -c "rm -rf ~"` hides the payload inside a quoted argument, so no amount
# of segment splitting sees it. Strip the `sh -c` wrapper and the quotes, then
# scan the result as a command in its own right.
unwrap_shell() {
    printf '%s' "$1" \
        | sed -E 's/(^|[;&|[:space:]])(ba|z|k|da)?sh[[:space:]]+-[a-zA-Z]*c[a-zA-Z]*[[:space:]]+/\1/g' \
        | tr -d "'\""
}

scan() {
    local haystack="$1" segment normalised
    check_patterns "$haystack"
    while IFS= read -r segment; do
        [[ -n ${segment//[[:space:]]/} ]] || continue
        normalised="$(normalise "$segment")"
        check_patterns "$normalised"
        check_rm "$normalised"
    done < <(split_segments "$haystack")
}

check() {
    local command="$1" unwrapped
    [[ -n ${command//[[:space:]]/} ]] || return 0

    shopt -s nocasematch

    # Guard integrity is checked against the raw string first, BEFORE the hatch
    # is honoured — the hatch has to be flipped by a human, not by an agent
    # talking itself into it. Reading or running the guard is fine; only writes
    # to it, and `guard off`, are blocked.
    if [[ $command =~ $INTEGRITY_WRITE || $command =~ $INTEGRITY_REDIRECT \
       || $command =~ $INTEGRITY_SED || $command =~ $INTEGRITY_DISARM ]]; then
        block "modifying or disarming the guard itself"
    fi

    # The hatch holds an epoch expiry, so a forgotten `guard off` re-arms itself.
    if [[ -f $ESCAPE_HATCH ]]; then
        local expiry
        expiry="$(cat "$ESCAPE_HATCH" 2>/dev/null)"
        [[ $expiry =~ ^[0-9]+$ && $(date +%s) -lt $expiry ]] && return 0
    fi

    scan "$command"
    unwrapped="$(unwrap_shell "$command")"
    [[ $unwrapped != "$command" ]] && scan "$unwrapped"
    return 0
}

selftest() {
    local failures=0 expect cmd
    local -a cases=(
        # expectation | command
        "block|rm -rf /"
        "block|rm -rf /*"
        "block|rm -rf ~"
        "block|rm -rf ~/"
        "block|rm -rf ~/projects/foo/node_modules"
        "block|rm -rf \$HOME/Documents"
        "block|sudo rm -rf /"
        "block|sudo /bin/rm -fr ~"
        "block|rm -r -f ~/stuff"
        "block|rm --recursive --force ~/stuff"
        "block|cd /tmp && rm -rf ~/data"
        "block|bash -c 'rm -rf ~'"
        "block|sh -c \"rm -rf \$HOME\""
        "block|zsh -lc 'rm -rf ~/projects'"
        "block|bash -lc 'diskutil eraseDisk JHFS+ X /dev/disk2'"
        "block|diskutil eraseDisk JHFS+ Untitled /dev/disk2"
        "block|diskutil apfs deleteContainer disk1"
        "block|mkfs.ext4 /dev/sda1"
        "block|dd if=/dev/zero of=/dev/disk0 bs=1m"
        "block|shutdown -h now"
        "block|sudo reboot"
        "block|git push --force origin main"
        "block|git push -f origin HEAD:master"
        "block|git branch -D main"
        "block|touch ~/.config/devconfig/guard-off"
        "block|guard off 60"
        "block|echo x > ~/projects/devconfig/agents/shared/guard/dangerous-patterns.txt"
        "block|sed -i '' 's/x/y/' ~/bin/codex-guard"
        "block|rm ~/projects/devconfig/agents/shared/guard/check-command.sh"
        "allow|cat ~/projects/devconfig/agents/shared/guard/dangerous-patterns.txt"
        "allow|~/projects/devconfig/agents/shared/guard/check-command.sh --selftest"
        "allow|guard status"
        "allow|guard test"
        "allow|rm -rf ./dist"
        "allow|rm -rf node_modules"
        "allow|rm -rf /tmp/scratch"
        "allow|rm foo.txt"
        "allow|rm -f package-lock.json"
        "allow|git push --force-with-lease origin my-feature"
        "allow|git push origin main"
        "allow|git branch -D my-feature"
        "allow|dd if=input.iso of=output.img"
        "allow|npm run build && npm test"
        "allow|echo 'shutdown the server gracefully'"
        "allow|grep -r 'reboot' ./src"
    )
    for case in "${cases[@]}"; do
        expect="${case%%|*}"
        cmd="${case#*|}"
        if ( check "$cmd" ) >/dev/null 2>&1; then
            [[ $expect == allow ]] || { printf 'FAIL expected block: %s\n' "$cmd"; ((failures++)); }
        else
            [[ $expect == block ]] || { printf 'FAIL expected allow: %s\n' "$cmd"; ((failures++)); }
        fi
    done
    if [[ $failures -eq 0 ]]; then
        printf 'guard selftest: %d cases, all passed\n' "${#cases[@]}"
    else
        printf 'guard selftest: %d failure(s) of %d\n' "$failures" "${#cases[@]}"
    fi
    return $((failures > 0))
}

if [[ ${1:-} == --selftest ]]; then
    selftest
    exit $?
fi

if [[ $# -gt 0 ]]; then
    check "$1"
else
    check "$(cat)"
fi
exit 0
