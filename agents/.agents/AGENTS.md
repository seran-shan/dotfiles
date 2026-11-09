# Global agent instructions

<!-- Single source for every coding agent on this machine: ~/.claude/CLAUDE.md imports it (@), ~/.codex/AGENTS.md symlinks it (`just link`), opencode.json lists it in `instructions`. Project AGENTS.md files override it. -->

## Working rules

- Read a file before editing it; check callers before changing a signature or renaming.
- Make the smallest change that fits the existing design. If nothing fits cleanly, stop and propose the refactor instead of bolting it on.
- No abstraction for a single call site; duplication beats premature indirection.
- Validate at system boundaries only; trust internal callers.
- No fallbacks: no `?? ""` / `|| "Unknown"` placeholders, default config or env values, or catch-and-substitute. Missing data fails loudly; nullable data stays null.
- Never suppress a type error (`as any`, `@ts-ignore`, bare `# type: ignore`) or swallow an exception.

## Testing and verifying

- List the ways it can fail before writing the code; tests cover those.
- Test through the real boundary. No tautological, change-detector or mock-call-only tests. Add a regression test only when existing coverage genuinely missed the bug.
- Verify with a medium-to-hard scenario, not the happy path, and leave a repeatable artifact (script, Playwright trace, curl transcript).
- Report failures with their output; never imply an unrun command passed.

## Communication

- Lead with the outcome, match length to the question, flag uncertainty. Correct earlier mistakes plainly.

## This machine

- zsh (`~/.config/zsh/conf.d/`), Homebrew (`~/dotfiles/Brewfile`), `just` (check the justfile first), `rg`, `fd`, `ast-grep`.
- Never commit, push or rewrite history unless asked in that turn.
- Machine-local secrets go in the gitignored `~/.zshrc.local`, never in a tracked file.
