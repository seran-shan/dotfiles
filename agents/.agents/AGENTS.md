# Global agent instructions

Canonical source of truth for every coding agent on this machine. Claude Code, Codex and OpenCode all resolve to THIS file; see "Fan-out" at the bottom.

Project-level `AGENTS.md` files override anything here.

## Communication

- Lead with the outcome. State what changed or what was found first, then detail.
- No preamble ("Great question!", "I'll help you with that"). Answer directly.
- Match brevity to the question. A one-line question gets a one-line answer.
- Flag uncertainty explicitly rather than presenting a guess as fact.
- When correcting an earlier statement, say so plainly and move on.

## Before changing code

- Read the file before editing it. Never infer contents from a filename.
- Match the conventions already in the file over any general preference.
- Check how a symbol is used elsewhere before renaming or changing a signature.
- If two approaches both work, take the one that adds fewer names and layers.

## Making changes

- Smallest correct change. A bug fix is not an invitation to refactor.
- No new abstraction for a single call site. Duplication beats premature indirection.
- Validate at system boundaries (user input, network, filesystem). Trust internal callers; do not add defensive checks for impossible states.
- Never suppress a type error. No `as any`, no `@ts-ignore`, no bare `# type: ignore`.
- Never swallow an exception with an empty handler.

## Verifying

- A change is not done because it looks right. Run something that proves it.
- Report failures with the actual output. Never imply a command passed when it was not run.
- Tests must pass as a consequence of correct code, never by special-casing the test's inputs or deleting the failing assertion.

## This machine

- Shell: zsh, configured in `~/.config/zsh/conf.d/` (numbered modules).
- Package manager: Homebrew. `~/dotfiles/Brewfile` is the manifest.
- Task runner: `just`. Check the `justfile` before writing a shell one-liner.
- Editor: Cursor (`$EDITOR`), Neovim with LazyVim for terminal work.
- Search: prefer `rg` over grep and `fd` over find; both are installed.
- Structural search/rewrite: `ast-grep` is available and beats regex for anything syntax-shaped.
- Never run `git commit`, `git push`, or any history-rewriting command unless explicitly asked in that turn.

## Secrets

- Tools that need auth manage their own tokens (`gh`, Claude Code, Codex). Never write a key into a tracked file; machine-local values go in the gitignored `~/.zshrc.local`.
- This dotfiles repo is public and `gitleaks` runs as a pre-commit hook.

## Fan-out

This file is the single source. Other tools reach it by reference, not by copy, so there is exactly one place to edit:

| Tool | Path | Mechanism |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `@` import directive |
| Codex | `~/.codex/AGENTS.md` | symlink, created by `just link` |
| OpenCode | `~/.config/opencode/opencode.json` | `instructions` array |
