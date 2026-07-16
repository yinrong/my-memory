#!/usr/bin/env bash
set -euo pipefail

repo_dir="${MY_MEMORY_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
state_dir="${MY_MEMORY_STATE_DIR:-$HOME/.local/state/my-memory}"
stamp_file="$state_dir/last-successful-push"
interval_days="${MY_MEMORY_INTERVAL_DAYS:-7}"
interval_seconds=$((interval_days * 24 * 60 * 60))

mkdir -p "$state_dir"

now="$(date +%s)"
if [[ -f "$stamp_file" ]]; then
  last_run="$(tr -cd '0-9' < "$stamp_file" || true)"
  if [[ -n "$last_run" ]] && (( now - last_run < interval_seconds )); then
    echo "my-memory: skipped; last successful run was less than ${interval_days} days ago"
    exit 0
  fi
fi

cd "$repo_dir"

branch="$(git rev-parse --abbrev-ref HEAD)"
git pull --rebase --autostash origin "$branch"

git add -A
if git diff --cached --quiet; then
  date +%s > "$stamp_file"
  echo "my-memory: no changes to push"
  exit 0
fi

git commit -m "sync: weekly memory update"
git push origin "$branch"
date +%s > "$stamp_file"
echo "my-memory: pushed weekly memory update"
