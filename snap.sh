#!/usr/bin/env bash
# snap.sh  Save a snapshot (git commit) of everything in this project.
#
#   ./snap.sh "what changed"     commit with this message
#   ./snap.sh                    asks for the message
#
# A message is required. Files in .gitignore are never included.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

msg="${*:-}"
if [[ -z "${msg// }" ]]; then
  read -r -p "Snapshot message: " msg
fi
if [[ -z "${msg// }" ]]; then
  echo "No message, nothing saved." >&2
  exit 1
fi

git add -A
if git diff --cached --quiet; then
  echo "Nothing changed since the last snapshot."
  exit 0
fi

echo "Saving:"
git diff --cached --stat
git commit -q -m "$msg"
echo "Snapshot $(git rev-parse --short HEAD): $msg"
