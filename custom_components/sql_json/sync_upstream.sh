#!/bin/bash
SCRIPT_DIR="$(dirname $(readlink -e $0 2>/dev/null || echo $0))"
WORKTREE=${SCRIPT_DIR%%/components/*}/worktrees/sql/homeassistant/components/sql
rsync -av $WORKTREE/ $SCRIPT_DIR
