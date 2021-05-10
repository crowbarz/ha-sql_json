#!/bin/bash
SCRIPT_DIR="$(dirname $(readlink -e $0 2>/dev/null || echo $0))"
WORKTREE=${SCRIPT_DIR%%/components/*}/worktrees/sql/homeassistant/components/sql
rsync -av \
    --exclude '__pycache__' --exclude '.git*' \
    $WORKTREE/ \
    $SCRIPT_DIR/custom_components/sql_json/
