# dotfiles

macOS development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/) and [`just`](https://github.com/casey/just). Zsh, Neovim (LazyVim), Ghostty, tmux, Homebrew, and the config for the AI coding agents I use.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/seran-shan/dotfiles/main/install.sh)"
```

## Requirements

- macOS on Apple Silicon or Intel. Nothing here targets Linux.
- An admin account. Homebrew's installer asks for `sudo` once.
- The bootstrap installs Xcode Command Line Tools, Homebrew, and everything in the Brewfile, including `stow` and `just`.

## What's inside

One directory per tool at the root, the same layout as [holman/dotfiles](https://github.com/holman/dotfiles).

```
dotfiles
├── zsh/          .zshrc + .config/zsh/conf.d/ (8 numbered modules)
├── git/          .gitconfig, global ignore
├── ssh/          .ssh/config (config ONLY, never keys)
├── ghostty/      terminal
├── tmux/
├── nvim/         LazyVim, with lazy-lock.json pinned
├── opencode/
├── agents/       AGENTS.md, one file read by Claude Code, Codex and OpenCode
├── claude/       settings.json
├── codex/        config.toml (portable preferences only)
├── cursor/       settings + keybindings
├── vscode/       settings + keybindings
│
├── setup/        run, never deployed
│   ├── macos.sh              system preferences        just macos
│   ├── packages/             npm · pnpm · go · uv · cursor extensions
│   ├── gitconfig.local.example
│   └── zshrc.local.example
│
├── Brewfile      every formula and cask    just brew
├── install.sh    fresh-machine bootstrap
├── justfile      every command, and which directories deploy how
└── .stowrc       makes a bare `stow zsh` behave like `just link`
```

Each tool directory mirrors `$HOME` inside: `zsh/.config/zsh/conf.d/00-path.zsh` becomes `~/.config/zsh/conf.d/00-path.zsh`.

### Two ways a directory reaches `$HOME`

The justfile lists which mechanism each tool uses. Directory location does not decide it.

|  | Tools | For | Why |
| --- | --- | --- | --- |
| **Symlink** `just link` | zsh git ssh ghostty tmux nvim opencode agents | Config the tool only reads | Editing the file in `~` edits the repo. Nothing to sync. |
| **Copy** `just sync` · `just editors` | claude codex cursor vscode | Config the tool rewrites at runtime | These write project-trust records, cache paths and UI state back into their own config files. Symlinked, that machine state would land in the git worktree. |

The live `~/.codex/config.toml` is around 80% generated content. Only the portable preferences are committed.

`just doctor` checks that every directory is claimed by exactly one of the two lists, so a new tool cannot be left undeployed or deployed twice.

## Installation

### Fresh machine

Run the one-liner at the top. It is idempotent and never overwrites an existing file. In order it:

1. installs Xcode Command Line Tools (exits after the GUI prompt; re-run once done)
2. installs Homebrew
3. clones this repo to `~/dotfiles`
4. runs `brew bundle` (the slow step)
5. **checks for conflicts** and stops with a list if any file in `~` would be replaced
6. symlinks the stow packages and copies the rest
7. seeds `~/.gitconfig.local` and `~/.ssh/config.local` from their templates

It then prints the remaining steps. They are manual because they are slow or change the system in ways worth reviewing first:

```bash
just tools      # npm / pnpm / go / uv globals
just editors    # VS Code and Cursor settings
just nvim       # LazyVim plugins, headless
just hooks      # pre-commit: gitleaks, shellcheck, prettier, private-key detection
just macos      # system preferences; read setup/macos.sh first
just doctor     # verify everything resolved
```

Finally, edit `~/.gitconfig.local`: git cannot commit until `name` and `email` are set.

### Existing machine

```bash
git clone https://github.com/seran-shan/dotfiles.git ~/dotfiles
cd ~/dotfiles
just check      # dry run: shows exactly what would be linked, changes nothing
just link       # symlink zsh, git, ssh, ghostty, tmux, nvim, opencode, agents
just sync       # copy claude and codex
just doctor
```

If `just check` reports conflicts, move the existing file aside (`mv ~/.zshrc ~/.zshrc.old`) and re-run. Stow does not overwrite files it did not create.

## Commands

`just` with no arguments lists everything. The ones you will actually use:

| Command | Does |
| --- | --- |
| `just check` | Dry-run the symlinking. Safe to run anytime. |
| `just link` / `unlink` / `relink` | Deploy, remove, or refresh every symlinked tool |
| `just sync` | Copy `claude/` and `codex/` into place |
| `just doctor` | Symlinks resolve into the repo, configs parse, tools present |
| `just brew` / `brew-check` / `brew-prune` | Install, diff, or remove-what's-not-listed |
| `just tools` / `tools-check` | Same for language-manager globals |
| `just macos` | Apply `setup/macos.sh`. Never runs on its own. |
| `just scan` | gitleaks over the whole history |

## Local customizations

Anything machine-specific or private lives in gitignored files that the committed config reads at runtime. Templates for each are in `setup/`.

**`~/.gitconfig.local`**: identity, and the opt-in for SSH commit signing. Pulled in by `[include]` from `.gitconfig`. Signing is off by default: with `gpgsign = true` and no `signingkey`, git refuses every commit, and a fresh machine could not commit until someone noticed.

**`~/.zshrc.local`**: sourced last by `.zshrc`, so it wins over every `conf.d` module. Client paths, work aliases, one-off `PATH` entries, and any raw API key a script needs.

**`~/.ssh/config.local`**: your servers. `Included` first thing by `.ssh/config`, so they inherit the `Host *` defaults (agent, connection reuse). Addresses and usernames stay out of the public repo.

Tool auth is not in this repo. `gh`, Claude Code and Codex each store their own OAuth token.

## Updating

Markdown is formatted by prettier with `proseWrap: never`: one paragraph per line, no hard wraps. Renderers reflow prose themselves; wrapping at 80 columns only makes a one-word edit show up as a rewrapped paragraph in every diff. The pre-commit hook enforces it, so you never run prettier by hand.

Edits to any symlinked tool are live immediately; the files in `~` are the repo files. For everything else:

```bash
just brew-check       # what's installed that the Brewfile doesn't know about
just tools-check      # same for npm globals
just editors-ext-dump # re-capture Cursor extensions into the manifest
just relink           # after adding or renaming files inside a stow package
```

Neovim plugin versions are pinned in `nvim/.config/nvim/lazy-lock.json`. Update with `:Lazy update` inside nvim; the lock file changes, commit it.

Adding a tool: `mkdir <name>`, mirror `$HOME` inside it, add the name to `STOW_PKGS` (or `COPY_PKGS`) in the justfile, `just link`. `just doctor` will refuse to pass until the name is in one of the lists.

## Uninstall

```bash
just unlink           # removes every symlink this repo created, nothing else
```

Copied files (`~/.claude/settings.json`, editor settings) and Homebrew packages are left in place. `just brew-prune` removes packages not in the Brewfile if you want to go further.

## Secrets

This repo is public and contains no secrets. Two layers keep it that way:

1. **`.gitignore` allowlist** for SSH: `ssh/.ssh/*` is denied and only `config` re-admitted. A newly generated key, public or private, cannot be committed by default. `*.pem` and `*.key` are blocked everywhere, as are the `.local` override files.
2. **gitleaks** as a pre-commit hook, plus `detect-private-key`. `just hooks` installs them; `just scan` audits the full history.

## Design decisions

**Topic directories, with the mechanism named in the justfile.** An earlier version nested everything under `stow/` and `copy/` so the directory name told you how it deployed. That meant knowing how a tool deploys before you could find its config, and none of the repos I compared against do it; holman, thoughtbot, xero and theskumar all put one directory per tool at the root. So the mechanism moved into two explicit lists in the justfile, and `just doctor` enforces that every directory is in exactly one. Explicit lists were kept over stow's `.stow-local-ignore` denylist for the same reason as before: with a denylist, one forgotten entry deploys a file to your home directory.

**`--no-folding`, always.** Stow's default "tree folding" symlinks a whole directory when the target does not exist yet. On a fresh machine that makes `~/.ssh` a symlink into this public repository, and every key `ssh-keygen` writes afterwards lands in the worktree. The flag is set in both `.stowrc` and the justfile.

**`node`, `go` and `bun` are explicit Brewfile entries.** All three were once installed only as transitive dependencies; `bun` had no dependant at all. Since `npm prefix -g` is `/opt/homebrew`, every global npm package lives inside Homebrew's tree, and losing `node` would have broken all of them.

**Language globals stay native.** Only 3 of 11 have a Homebrew formula, and `wrangler` / `prisma` need per-project versions a single global copy cannot provide. They are listed in `setup/packages/` instead.

**`air` is not the Homebrew formula.** A `brew` formula named `air` exists at 0.11.0. The installed tool is `github.com/air-verse/air` v1.65, an unrelated project sharing a name.

**One Node manager.** Homebrew's `node`. `volta` was installed but managed nothing, and the `zsh-nvm` plugin created `~/.nvm` without ever providing the active `node`, so both were removed.

**`AGENTS.md` has one source.** [`agents/.agents/AGENTS.md`](agents/.agents/AGENTS.md) is canonical. Claude Code reaches it with an `@` import, OpenCode with its `instructions` array, Codex with a symlink created by `just link`. There is no generator script and nothing to keep in sync.

**SSH commit signing, not GPG.** The existing `~/.ssh/id_ed25519` is reused, so there is no new key to generate, back up or rotate. Opt-in via `~/.gitconfig.local`.

**No `insteadOf` rewrite to SSH for GitHub.** `gh auth login` stores an OAuth token in the keychain and sets git operations to HTTPS. Rewriting URLs to SSH would fight that setup and break on networks that block port 22.

## Inspiration

- [nicksp/dotfiles](https://github.com/nicksp/dotfiles): the `setup/` split, `.local` override files, npm hardening (`save-exact`, `allow-git none`, `min-release-age 7`), and this README's section order
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles): the `.gitconfig.local` include pattern
- [omerxx/dotfiles](https://github.com/omerxx/dotfiles): `.stowrc` as the place stow options live
- [magnusrodseth/dotfiles](https://github.com/magnusrodseth/dotfiles): `just` as the task runner, the `doctor` recipe, and a bootstrap that deploys config even when a package fails
- [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles): the checklist this was reviewed against
- [yannbertrand/macos-defaults](https://github.com/yannbertrand/macos-defaults): documented `defaults write` keys
