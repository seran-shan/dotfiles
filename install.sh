#!/usr/bin/env bash
#
# Bootstrap a fresh macOS machine.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/seran-shan/dotfiles/main/install.sh)"
#
# Kept minimal. Its only job is to get Homebrew, git and `just`
# installed, then hand over to the justfile. Everything else is a `just`
# recipe, so it can be re-run individually and read in one place.
#
# Safe to re-run: every step is idempotent.

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/seran-shan/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
info() { printf '  %s\n' "$1"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "This bootstrap targets macOS only."

# ─── 1. Xcode Command Line Tools ─────────────────────────────────────────────
# Provides git and the compilers Homebrew needs.
bold "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  info "already installed"
else
  info "installing. Accept the GUI prompt, then re-run this script"
  xcode-select --install
  exit 0
fi

# ─── 2. Homebrew ─────────────────────────────────────────────────────────────
bold "Homebrew"
if command -v brew >/dev/null 2>&1; then
  info "already installed"
else
  info "installing"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for the remainder of this script. Apple Silicon installs to
# /opt/homebrew, Intel to /usr/local; the login shell gets this from .zshrc.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  die "Homebrew installed but brew not found on the expected paths."
fi

# ─── 3. Clone the repository ─────────────────────────────────────────────────
bold "Dotfiles repository"
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  info "already present at $DOTFILES_DIR"
else
  info "cloning into $DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi
cd "$DOTFILES_DIR"

# ─── 4. Packages ─────────────────────────────────────────────────────────────
# Installs stow and just among everything else, which the next step needs.
bold "Homebrew packages (this takes a while)"

# Homebrew 6 refuses to load anything from a third-party tap until that tap is
# trusted, and a `tap` line in the Brewfile only ADDS it. Trust is recorded in
# ~/.homebrew/trust.json, so a fresh machine has none. Derive the list from
# the Brewfile so it cannot drift from what is actually installed.
while IFS= read -r tap; do
  [[ -n "$tap" ]] || continue
  info "trusting tap $tap"
  brew trust --tap "$tap" >/dev/null
done < <(sed -nE 's/^tap "([^"]+)".*/\1/p' "$DOTFILES_DIR/Brewfile")

# A single failing cask (a download that 404s, a tap that needs trust) must
# not abort the bootstrap before any config is deployed. Record the failure,
# carry on, and surface it at the end.
BREW_FAILED=0
brew bundle install --file="$DOTFILES_DIR/Brewfile" || BREW_FAILED=1

# The rest of this script needs these two. They are in the Brewfile, so they
# only go missing if bundle failed early; say so precisely rather than dying
# on a "command not found" three steps later.
for t in stow just; do
  command -v "$t" >/dev/null 2>&1 || die "'$t' is missing; brew bundle did not get far enough. Fix the error above and re-run."
done

# ─── 5. Check for conflicts BEFORE touching $HOME ────────────────────────────
# stow refuses to overwrite a file it does not own, and it would otherwise fail
# midway through the package loop leaving $HOME half-linked. Surface every
# conflict up front instead, with the exact files to move out of the way.
bold "Checking for conflicts"
if conflicts=$(just check 2>&1 | grep -iE 'conflict|existing target' | sort -u); [[ -n "$conflicts" ]]; then
  printf '%s\n' "$conflicts" | sed 's/^/  /'
  cat <<'EOF'

  Existing files in your home directory would be overwritten. This script will
  not do that for you. Move or delete each file listed above, then re-run.
  A typical first cutover from a stock macOS install looks like:

    mv ~/.zshrc ~/.zshrc.pre-dotfiles
EOF
  exit 1
fi
info "no conflicts"

# ─── 6. Hand over to just ────────────────────────────────────────────────────
bold "Linking configuration"
just link
just sync

# ─── 7. Git identity ─────────────────────────────────────────────────────────
# user.name / user.email live in ~/.gitconfig.local, which is gitignored. Git
# refuses to commit at all without them, so seed the file from the template
# rather than leaving a fresh machine unable to commit until someone notices.
bold "Git identity"
if [[ -f "$HOME/.gitconfig.local" ]]; then
  info "$HOME/.gitconfig.local already present, leaving it alone"
else
  cp "$DOTFILES_DIR/setup/gitconfig.local.example" "$HOME/.gitconfig.local"
  chmod 600 "$HOME/.gitconfig.local"
  info "created ~/.gitconfig.local from the template. EDIT name and email"
fi

# ─── 8. Machine-local SSH hosts ──────────────────────────────────────────────
# ~/.ssh/config Includes this file; servers and IPs never enter the repository.
if [[ -f "$HOME/.ssh/config.local" ]]; then
  info "\$HOME/.ssh/config.local already present, leaving it alone"
else
  cp "$DOTFILES_DIR/setup/ssh-config.local.example" "$HOME/.ssh/config.local"
  chmod 600 "$HOME/.ssh/config.local"
  info "created ~/.ssh/config.local from the template. Add your hosts there"
fi

if [[ $BREW_FAILED -eq 1 ]]; then
  bold "Done, with package failures"
  info "Some Brewfile entries did not install (see above). Configuration is"
  info "deployed regardless. Re-run 'just brew' once the cause is fixed."
else
  bold "Done."
fi
cat <<'EOF'

Remaining steps, each run by hand:

  just tools      install npm / pnpm / go / uv global packages
  just editors    copy VS Code and Cursor settings into place
  just nvim       bootstrap Neovim plugins
  just hooks      install the gitleaks pre-commit hook
  just macos      apply system preferences (review setup/macos.sh first)
  just doctor     verify everything resolved correctly

Edit ~/.gitconfig.local; git cannot commit until name and email are set.
It also holds the opt-in for SSH commit signing.
Add your servers to ~/.ssh/config.local; they get the Host * defaults.

Open a new terminal to pick up the new shell configuration.
EOF
