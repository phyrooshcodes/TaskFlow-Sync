#!/usr/bin/env bash
REPO_DIR="/home/qwen/TaskFlow-Sync"
cd "$REPO_DIR" || exit 1

if [[ -f todo.json ]] && [[ -n $(git status --porcelain todo.json) ]]; then
    git add todo.json
    git commit -m "Auto-backup $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main >> /home/qwen/TaskFlow-Sync/backup.log 2>&1
fi
