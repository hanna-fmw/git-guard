# git-guard

A small bash pre-commit hook that catches sensitive content before it leaves your machine — paths with your username, real names, client emails, server IPs, AI assistant config files (`CLAUDE.md`, `.claude/`, `AGENTS.md`, `GEMINI.md`), local-only folders (`private/`, `docs/`), and anything else you flag. When something matches, the commit is blocked and (on macOS) you get an unmissable dialog with three buttons: **Cancel**, **Open in editor**, or **Commit anyway**.

Designed for people working with AI coding assistants (Claude Code, Cursor, Copilot, Codex) where a "helpful" `git add .` can sweep in machine-local config and absolute paths before you notice.

## Why

Git has `.gitignore`. AI assistants sometimes use `git add -f` or commit files that were already tracked. `.gitignore` doesn't help with either. This hook does — at the git layer itself, after every other check. The commit object is never created if a pattern matches.

## Install

```sh
git clone https://github.com/hanna-fmw/git-guard.git
cd git-guard
./install.sh
```

The installer:

- Copies `pre-commit` to `~/.git-hooks/pre-commit`.
- Copies `sensitive-patterns.example` → `~/.git-hooks/sensitive-patterns` (only if missing — never overwrites your tuned version).
- Copies `blocked-paths.example` → `~/.git-hooks/blocked-paths` (same rule).
- Sets `git config --global core.hooksPath ~/.git-hooks` so every repo uses these.

Now edit `~/.git-hooks/sensitive-patterns` and add your real values (names, client emails, phone format, public IPs). The example file has commented-out templates to copy from.

For an extra silent layer, add the AI-assistant file names to `~/.gitignore_global`:

```sh
git config --global core.excludesFile ~/.gitignore_global
cat >> ~/.gitignore_global <<EOF
CLAUDE.md
.claude/
AGENTS.md
GEMINI.md
private/
docs/
EOF
```

## How it works

The hook runs on every `git commit`. It does two checks:

### Check 1 — file path block

Reads `~/.git-hooks/blocked-paths`. Each line is a POSIX extended regex matched against `git diff --cached --name-only --diff-filter=AM` (added / modified, not deleted). If any staged path matches, the commit is blocked.

Default `blocked-paths.example` blocks: `CLAUDE.md`, `.claude/`, `AGENTS.md`, `GEMINI.md`, `docs/`, `private/`.

Deletions of blocked files are allowed — you're allowed to clean up.

### Check 2 — content scan

Reads `~/.git-hooks/sensitive-patterns`. Each line is a POSIX extended regex matched against the **added** lines of the staged diff (lines starting `+` in `git diff --cached --unified=0`). Only addition lines are scanned, so old tracked content doesn't keep triggering forever.

If any added line matches, the commit is blocked.

#### Content allowlist (skip the scan for specific files)

Some files are *supposed* to contain your name, email, or other personal info that would otherwise match your patterns. Forcing a "Commit anyway" click every time you touch them is noise, not safety. Add their path regex to `~/.git-hooks/content-allowlist` (one regex per line, `#` for comments) and the content scan will skip those files. The path-block check (Check 1) still runs normally.

Default shipped allowlist covers common open-source author-attribution files:

```
(^|/)LICENSE(\.md|\.txt)?$
(^|/)COPYING(\.md|\.txt)?$
(^|/)NOTICE(\.md|\.txt)?$
(^|/)AUTHORS(\.md|\.txt)?$
(^|/)COPYRIGHT(\.md|\.txt)?$
```

Other common things people add to their own allowlist:

```
# Personal portfolio / CV — your name and contact are the whole point
(^|/)cv\.(md|tex|pdf)$
(^|/)resume\.(md|tex|pdf)$
src/app/about/page\.(tsx|jsx)$        # portfolio "About me" page
(^|/)README\.md$                       # if your repo READMEs greet by name

# Project pages where your support email is meant to be visible
src/app/help/page\.(tsx|jsx)$
src/components/footer\.(tsx|jsx)$
```

Each line is its own regex — add what fits your projects, skip the rest.

### When something is blocked

On macOS:

- The Sosumi alert sound plays.
- A modal dialog opens with the exact file:line:match list and three buttons:
  - **Cancel** (default) — commit stays blocked. Safe walk-away option.
  - **Open in editor** — opens the offending files in VS Code so you can scrub. Commit stays blocked; re-stage and retry.
  - **Commit anyway** — bypasses the check for this one commit only. Equivalent to `git commit --no-verify`.

On non-macOS or non-GUI sessions, the dialog and sound are skipped — the terminal output is the same: explicit list, three options (do nothing / scrub / `--no-verify`).

## Configure

- **Edit patterns:** `~/.git-hooks/sensitive-patterns`
- **Edit blocked paths:** `~/.git-hooks/blocked-paths`
- **Per-repo opt-out (e.g. for a repo whose automated sync legitimately commits flagged content):**
  ```sh
  git config hooks.skipSensitiveCheck true
  ```
- **Override one commit:** `git commit --no-verify`

The script honors two env vars if you want to keep config files elsewhere:

```sh
GIT_HOOKS_PATTERNS=/path/to/patterns
GIT_HOOKS_BLOCKED_PATHS=/path/to/blocked
```

## Pair with AI assistant restrictions

If you use Claude Code, add a permission deny rule so the assistant can't `--no-verify` past the hook on its own. In `~/.claude/settings.json`:

```json
"permissions": {
  "deny": [
    "Bash(*--no-verify*)",
    "Bash(*--no-gpg-sign*)",
    "Bash(git config*core.hooksPath*)",
    "Bash(git config*hooks.skipSensitiveCheck*)"
  ]
}
```

Combined with the hook, this means: an AI session cannot bypass without an explicit per-prompt permission you click through.

## Uninstall

```sh
./uninstall.sh
```

Removes the hook script and unsets `core.hooksPath`. Leaves your `sensitive-patterns` and `blocked-paths` files on disk (so you don't lose your tuning if you reinstall later).

## License

MIT — see [LICENSE](LICENSE).
