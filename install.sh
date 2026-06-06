#!/bin/bash
# git-guard installer.
#
# - Installs the pre-commit hook to ~/.git-hooks/
# - Copies sensitive-patterns and blocked-paths from .example files
#   (only if the user doesn't already have them — never overwrites).
# - Points git's global core.hooksPath at ~/.git-hooks.
# - Optionally adds patterns to ~/.gitignore_global as a silent first layer.
#
# Re-run any time after editing the source files in this folder.

set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.git-hooks"

echo "git-guard installer"
echo "  source : $SRC"
echo "  target : $DEST"
echo ""

mkdir -p "$DEST"

# Hook script — overwrite (script content is what we ship + maintain).
cp "$SRC/pre-commit" "$DEST/pre-commit"
chmod +x "$DEST/pre-commit"
echo "installed: $DEST/pre-commit"

# Config files — copy from .example only if missing, never clobber.
for name in sensitive-patterns blocked-paths; do
  example="$SRC/$name.example"
  target="$DEST/$name"
  if [ -f "$target" ]; then
    echo "kept    : $target (already exists — edit it to tune patterns)"
  else
    cp "$example" "$target"
    echo "installed: $target"
  fi
done

# Wire git up — silent if already set to this value.
current_hooks_path=$(git config --global core.hooksPath || true)
if [ "$current_hooks_path" = "$DEST" ]; then
  echo "config  : core.hooksPath already set to $DEST"
else
  git config --global core.hooksPath "$DEST"
  echo "config  : set core.hooksPath = $DEST"
  if [ -n "$current_hooks_path" ]; then
    echo "  (previous value was: $current_hooks_path)"
  fi
fi

echo ""
echo "Done."
echo ""
echo "Next steps:"
echo "  1. Edit $DEST/sensitive-patterns to add your real names, emails,"
echo "     phone formats, and any private IPs you want flagged."
echo "  2. (Optional) Edit $DEST/blocked-paths to add more never-commit files."
echo "  3. Try a test commit in any repo — the hook runs automatically."
echo ""
echo "Tip — also add these to ~/.gitignore_global as a silent first layer:"
echo "  CLAUDE.md"
echo "  .claude/"
echo "  AGENTS.md"
echo "  GEMINI.md"
echo "  private/"
echo "  docs/"
echo "  (and configure git: git config --global core.excludesFile ~/.gitignore_global)"
