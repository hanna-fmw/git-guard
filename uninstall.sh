#!/bin/bash
# git-guard uninstaller.
#
# Removes the hook + clears git's global hooksPath. Does NOT delete your
# sensitive-patterns or blocked-paths files — those are your data; you may
# want them back if you reinstall.

set -euo pipefail

DEST="$HOME/.git-hooks"

if [ -f "$DEST/pre-commit" ]; then
  rm "$DEST/pre-commit"
  echo "removed: $DEST/pre-commit"
else
  echo "skip   : $DEST/pre-commit (not present)"
fi

current_hooks_path=$(git config --global core.hooksPath || true)
if [ "$current_hooks_path" = "$DEST" ]; then
  git config --global --unset core.hooksPath
  echo "config : unset core.hooksPath"
else
  echo "config : core.hooksPath is '$current_hooks_path' (not ours — leaving it)"
fi

echo ""
echo "Done. Your patterns at $DEST/sensitive-patterns and $DEST/blocked-paths"
echo "are still on disk — delete manually if you want a fully clean state."
