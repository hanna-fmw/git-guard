#!/bin/bash
# Retired 2026-10-27. The live pre-commit hook is dotfiles/git-hooks/pre-commit (~/.git-hooks is a
# link to it). This installer used to copy an older pre-commit over it, one where approving the
# path dialog skipped the content scan. Nothing to install here any more.
echo "git-guard is retired: the pre-commit hook lives in dotfiles/git-hooks. Nothing was changed." >&2
exit 1
