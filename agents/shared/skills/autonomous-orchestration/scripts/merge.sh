#!/bin/bash
# usage: merge.sh BRANCH "verb: title (Tn)" BODY_FILE   (set INTEGRATION_DIR, INTEGRATION_BRANCH, REPO)
set -e
BR=$1; TITLE=$2; BODY=$3
I=${INTEGRATION_DIR:?}; IB=${INTEGRATION_BRANCH:?}; REPO=${REPO:?}
git -C "$I" push -q origin "$BR"
URL=$(gh pr create --repo "$REPO" --base "$IB" --head "$BR" --title "$TITLE" --body-file "$BODY")
gh pr merge "$URL" --merge --subject "$TITLE" --body "$URL"
cd "$I" && git pull -q --ff-only origin "$IB" && git log --oneline -1
echo "$URL"
