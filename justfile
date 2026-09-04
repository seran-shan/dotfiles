# Dotfiles task runner.  `just` with no arguments lists everything.
#
# Every top-level directory is one TOOL (holman-style topic layout). Two
# deployment mechanisms exist, and which one a tool uses is decided HERE, by
# name, never by where the directory sits:
#
#   STOW_PKGS  symlinked by `just link`. Each mirrors $HOME inside (zsh/.zshrc,
#              nvim/.config/nvim/...). Edits in ~ write through to the repo.
#   COPY_PKGS  copied by `just sync` / `just editors`. These tools REWRITE their
#              own config at runtime (Claude, Codex, Cursor, VS Code). Symlinked,
#              they would write machine state straight into the git worktree.
#
# setup/ is neither: scripts and manifests that are run, not deployed.

set shell := ["bash", "-euo", "pipefail", "-c"]

DOTFILES := justfile_directory()
STOW_PKGS := "zsh git ssh ghostty tmux nvim opencode agents"
COPY_PKGS := "claude codex cursor vscode"

# .stowrc holds the same flags so a bare `stow zsh` from this directory behaves
# identically. It cannot hold comments (stow reads it word by word), so:
#
#   --no-folding is a SECURITY requirement, not a preference. Without it stow
#   "tree-folds": when ~/.ssh does not exist yet it creates
#   ~/.ssh -> dotfiles/ssh/.ssh, and every key ssh-keygen writes after that
#   lands inside this public repository. Same hazard for ~/.claude (session
#   history) and ~/.config/opencode. With --no-folding only the individual
#   files are linked; the directories stay real.
STOW := "stow --dir=" + DOTFILES + " --target=" + env_var("HOME") + " --no-folding"

# List available recipes.
default:
    @just --list --unsorted

# ─── Stow ────────────────────────────────────────────────────────────────────

# Dry run: show what `just link` would do, changing nothing.
check:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Simulating stow into $HOME (no changes made)…"
    for pkg in {{STOW_PKGS}}; do
        echo "── $pkg"
        {{STOW}} --no --verbose=2 "$pkg" 2>&1 \
            | grep -vE '^(BUG|WARNING: in simulation mode)' | sed 's/^/   /' || true
    done

# Symlink every stow package into $HOME.
link:
    #!/usr/bin/env bash
    set -euo pipefail
    # Directories that will hold secrets or app state must exist as REAL
    # directories with the right mode before stow runs. --no-folding (see
    # .stowrc) then links only the files inside them. Without this, a fresh
    # machine would get ~/.ssh as a symlink INTO this public repository.
    install -d -m 700 "$HOME/.ssh"
    install -d -m 755 "$HOME/.config" "$HOME/.claude" "$HOME/.agents" "$HOME/.codex"
    for pkg in {{STOW_PKGS}}; do
        # ${pkg} braces are REQUIRED: a bare $pkg immediately followed by a
        # multi-byte character (the ellipsis) makes bash read those bytes as
        # part of the variable name, which trips `set -u`.
        echo "Linking ${pkg}..."
        {{STOW}} --restow "${pkg}"
    done
    # Codex has no import directive, so it gets a symlink to the canonical file.
    # Claude uses an @import and OpenCode an `instructions` array; both already
    # point at ~/.agents/AGENTS.md, so neither needs anything here.
    mkdir -p "$HOME/.codex"
    ln -sfn "$HOME/.agents/AGENTS.md" "$HOME/.codex/AGENTS.md"
    echo "Linked. Run 'just sync' for the copy-tier configs."

# Remove every symlink this repo created.
unlink:
    #!/usr/bin/env bash
    set -euo pipefail
    for pkg in {{STOW_PKGS}}; do
        echo "Unlinking ${pkg}..."
        {{STOW}} --delete "${pkg}"
    done
    rm -f "$HOME/.codex/AGENTS.md"

# Unlink then link. Use after adding or renaming files in a package.
relink: unlink link

# ─── Homebrew ────────────────────────────────────────────────────────────────

# Install everything in the Brewfile.
brew:
    brew bundle install --file="{{DOTFILES}}/Brewfile"

# Report packages installed on this machine but absent from the Brewfile.
brew-check:
    @brew bundle check --file="{{DOTFILES}}/Brewfile" --verbose || true

# Remove anything NOT in the Brewfile. Destructive; asks first.
brew-prune:
    brew bundle cleanup --file="{{DOTFILES}}/Brewfile"

# ─── Language-manager globals ────────────────────────────────────────────────

# Install the npm / pnpm / go / uv packages listed in setup/packages/.
tools:
    #!/usr/bin/env bash
    set -euo pipefail
    strip() { grep -vE '^\s*(#|$)' "$1" || true; }

    # npm hardening, adopted from nicksp/dotfiles setup/misc.sh.
    # min-release-age is the important one: it refuses packages published in
    # the last 7 days, which is the window most supply-chain attacks live in.
    npm config set loglevel warn
    npm config set fund false
    npm config set save-exact true
    npm config set allow-git none
    npm config set min-release-age 7

    echo "── npm"
    # Built with a read loop rather than `mapfile`: macOS ships bash 3.2 and
    # /usr/bin/env bash resolves to it, where mapfile does not exist.
    # Installed in one npm call so dependencies resolve together.
    pkgs=()
    while IFS= read -r p; do [[ -n "$p" ]] && pkgs+=("$p"); done < <(strip "{{DOTFILES}}/setup/packages/npm.txt")
    [[ ${#pkgs[@]} -gt 0 ]] && npm install -g "${pkgs[@]}"

    echo "── pnpm"
    while read -r p; do [[ -n "$p" ]] && pnpm add -g "$p"; done < <(strip "{{DOTFILES}}/setup/packages/pnpm.txt")

    echo "── go"
    while read -r p; do [[ -n "$p" ]] && go install "$p"; done < <(strip "{{DOTFILES}}/setup/packages/go.txt")

    echo "── uv"
    while read -r p; do [[ -n "$p" ]] && uv tool install "$p"; done < <(strip "{{DOTFILES}}/setup/packages/uv.txt")

# Report drift between setup/packages/*.txt and what is actually installed.
tools-check:
    #!/usr/bin/env bash
    set -euo pipefail
    strip() { grep -vE '^\s*(#|$)' "$1" || true; }
    echo "── npm: installed but not in setup/packages/npm.txt"
    comm -23 <(npm ls -g --depth=0 --parseable 2>/dev/null | sed '1d; s|.*/node_modules/||' | sort -u) \
             <(strip "{{DOTFILES}}/setup/packages/npm.txt" | sort -u) | sed 's/^/   /'
    echo "── npm: in manifest but NOT installed"
    comm -13 <(npm ls -g --depth=0 --parseable 2>/dev/null | sed '1d; s|.*/node_modules/||' | sort -u) \
             <(strip "{{DOTFILES}}/setup/packages/npm.txt" | sort -u) | sed 's/^/   /'

# ─── Copy-deployed tools (COPY_PKGS) ─────────────────────────────────────────

# Copy (never symlink) configs for tools that rewrite their own files.
sync:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.claude" "$HOME/.codex"
    cp "{{DOTFILES}}/claude/settings.json" "$HOME/.claude/settings.json"
    cp "{{DOTFILES}}/codex/config.toml"    "$HOME/.codex/config.toml"
    echo "Copied claude/settings.json and codex/config.toml."
    echo "NOTE: codex/config.toml holds portable preferences only. Codex"
    echo "      regenerates its project-trust and marketplace state itself."

# Copy editor settings into their macOS application-support paths.
editors:
    #!/usr/bin/env bash
    set -euo pipefail
    for pair in "vscode:Code" "cursor:Cursor"; do
        src="{{DOTFILES}}/${pair%%:*}"
        dst="$HOME/Library/Application Support/${pair##*:}/User"
        [[ -d "$dst" ]] || { echo "skip ${pair##*:} (not installed)"; continue; }
        cp "$src/settings.json"    "$dst/settings.json"
        cp "$src/keybindings.json" "$dst/keybindings.json"
        echo "Synced ${pair##*:}."
    done

# Install the Cursor extensions listed in setup/packages/cursor-extensions.txt.
editors-ext:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v cursor >/dev/null 2>&1 || { echo "cursor CLI not on PATH"; exit 1; }
    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        echo "── $ext"
        cursor --install-extension "$ext" --force
    done < "{{DOTFILES}}/setup/packages/cursor-extensions.txt"

# Re-capture the installed Cursor extensions into the manifest.
editors-ext-dump:
    #!/usr/bin/env bash
    set -euo pipefail
    out="{{DOTFILES}}/setup/packages/cursor-extensions.txt"
    head -5 "$out" > "$out.tmp"
    ls -1 "$HOME/.cursor/extensions" | grep -vE '^\.' \
        | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+.*$//' | sort -u >> "$out.tmp"
    mv "$out.tmp" "$out"
    echo "Captured $(grep -vcE '^\s*(#|$)' "$out") extensions."

# ─── System ──────────────────────────────────────────────────────────────────

# Apply macOS system preferences. Never runs on its own.
macos:
    bash "{{DOTFILES}}/setup/macos.sh"

# Install the pre-commit hooks: gitleaks, shellcheck, prettier, private-key detection.
hooks:
    pre-commit install --install-hooks

# Scan the whole history for committed secrets.
scan:
    gitleaks detect --source="{{DOTFILES}}" --verbose

# Bootstrap Neovim: installs plugins headlessly, then exits.
nvim:
    nvim --headless "+Lazy! sync" +qa

# ─── Diagnostics ─────────────────────────────────────────────────────────────

# Verify the deployed setup: symlinks resolve, configs parse, tools present.
doctor:
    #!/usr/bin/env bash
    set -uo pipefail
    fail=0
    echo "── deployed files resolve into the repo"
    # Testing `-L` on the file itself is WRONG: stow tree-folds, symlinking a
    # whole directory (e.g. ~/.config/nvim) when the target does not exist yet.
    # The file underneath is then a real file reached THROUGH a directory
    # symlink. What actually matters is where the path physically resolves.
    for f in .zshrc .gitconfig .ssh/config .tmux.conf .config/ghostty/config \
             .config/nvim/init.lua .config/opencode/opencode.json .agents/AGENTS.md \
             .claude/CLAUDE.md .codex/AGENTS.md; do
        if [[ ! -e "$HOME/$f" ]]; then printf '   missing %s\n' "$f"; fail=1; continue; fi
        # `realpath` follows symlinks on the FILE too. Resolving only the
        # parent with `pwd -P` misses the common case where the file itself
        # is the symlink (which is what stow creates when it cannot fold).
        phys="$(realpath "$HOME/$f" 2>/dev/null || echo unresolved)"
        case "$phys" in
            "{{DOTFILES}}"/*) printf '   ok      %s\n' "$f" ;;
            *)                printf '   STRAY   %s -> %s\n' "$f" "$phys"; fail=1 ;;
        esac
    done
    echo "── every topic directory is claimed by exactly one mechanism"
    # A directory that is in neither list would be silently undeployed; one in
    # both would be deployed twice. Catch both at `just doctor` time.
    for d in $(ls -d "{{DOTFILES}}"/*/ | xargs -n1 basename); do
        [[ "$d" == setup ]] && continue
        in_stow=$([[ " {{STOW_PKGS}} " == *" $d "* ]] && echo 1 || echo 0)
        in_copy=$([[ " {{COPY_PKGS}} " == *" $d "* ]] && echo 1 || echo 0)
        case "$((in_stow + in_copy))" in
            1) printf '   ok      %s\n' "$d" ;;
            0) printf '   ORPHAN  %s (in neither STOW_PKGS nor COPY_PKGS)\n' "$d"; fail=1 ;;
            *) printf '   DOUBLE  %s (in both lists)\n' "$d"; fail=1 ;;
        esac
    done
    echo "── config parses"
    zsh -n "$HOME/.zshrc" 2>/dev/null && echo "   ok      .zshrc syntax" || { echo "   FAIL    .zshrc syntax"; fail=1; }
    git config --file "$HOME/.gitconfig" --list >/dev/null 2>&1 && echo "   ok      .gitconfig" || { echo "   FAIL    .gitconfig"; fail=1; }
    ssh -F "$HOME/.ssh/config" -G github.com >/dev/null 2>&1 && echo "   ok      .ssh/config" || { echo "   FAIL    .ssh/config"; fail=1; }
    echo "── required tools"
    for t in stow just brew git nvim tmux fzf rg fd eza bat; do
        command -v "$t" >/dev/null 2>&1 && printf '   ok      %s\n' "$t" || { printf '   MISSING %s\n' "$t"; fail=1; }
    done
    echo
    [[ $fail -eq 0 ]] && echo "All checks passed." || echo "Some checks failed (see above)."
    exit $fail
