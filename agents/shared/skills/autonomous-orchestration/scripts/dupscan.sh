#!/bin/bash
# usage: dupscan.sh WORKTREE_DIR OUTFILE  -- whole-codebase duplicate scan, keeping only clones that involve the branch's changed files
WT=$1; OUT=$2
cd "$WT/backend" || exit 0
CHANGED=$(cd "$WT" && git diff --name-only ${INTEGRATION_BRANCH:-main}...HEAD -- '*.py' | sed 's#^backend/##')
[ -z "$CHANGED" ] && { echo "No changed Python files." > "$OUT"; exit 0; }
uvx --quiet --from pylint pylint --disable=all --enable=duplicate-code --min-similarity-lines=6 app packages/taisk_finance/src gateway 2>/dev/null \
 | python3 -c '
import sys,re
changed=set(sys.argv[1].split())
blocks=re.split(r"\n(?=\S+:\d+:\d+: R0801)", sys.stdin.read())
keep=[b for b in blocks if "R0801" in b and any(c.replace("/",".").removesuffix(".py") in b or c in b for c in changed)]
print(f"Duplicate-code scan (pylint R0801, whole backend), {len(keep)} clone groups involving this branch'"'"'s changed files:\n")
print("\n\n".join(keep) if keep else "None found.")
' "$CHANGED" > "$OUT"
