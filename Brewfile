# Brewfile. Install with `just brew` (or `brew bundle --file Brewfile`).
#
# Generated from `brew leaves` (43 explicitly-installed formulae), NOT
# `brew list` (210 including every transitive dependency). Dependencies
# resolve automatically; listing them only creates noise.

tap "oven-sh/bun"

# ═══ Dotfiles machinery ══════════════════════════════════════════════════════
brew "stow"                   # symlink manager; the whole repo depends on it
brew "just"                   # task runner; see justfile
brew "pre-commit"             # runs the gitleaks hook
brew "prettier"               # markdown formatting via pre-commit (.prettierrc)
brew "shellcheck"             # shell linting via pre-commit
brew "gitleaks"               # blocks key-shaped strings from being committed

# ═══ Shell ═══════════════════════════════════════════════════════════════════
brew "atuin"                  # searchable shell history (also a zinit plugin)
brew "fzf"                    # fuzzy finder; powers fzf-tab completion
brew "eza"                    # ls replacement
brew "bat"                    # cat with syntax highlighting
brew "fd"                     # find replacement
brew "ripgrep"                # grep replacement
brew "jq"                     # JSON processor
brew "wget"
brew "tmux"

# ═══ Git ═════════════════════════════════════════════════════════════════════
brew "git"
brew "gh"                     # GitHub CLI
brew "git-delta"              # diff pager; configured in git/.gitconfig
brew "git-lfs"
brew "lazygit"                # terminal git UI
brew "gitmoji"                # commit-message emoji picker

# ═══ Editor ══════════════════════════════════════════════════════════════════
brew "neovim"                 # LazyVim config lives in nvim/

# ═══ Runtimes ════════════════════════════════════════════════════════════════
# All three of node, go and bun were installed WITHOUT being explicit leaves.
# That is fragile: each survived only as a transitive dependency, so dropping
# an unrelated package could silently remove a runtime.
#   node <- gitmoji, vercel, yaml-language-server
#   go   <- go-blueprint  (single dependant!)
#   bun  <- nothing at all: an orphaned dependency, yet actively used
#           (~/.config/opencode/bun.lock) and on PATH
# `npm prefix -g` is /opt/homebrew, so all 9 global npm packages live inside
# brew's tree; losing node would break every one of them.
brew "node"
brew "go"
brew "oven-sh/bun/bun"        # tapped formula, not core, so it needs the full path
brew "uv"                     # Python packaging + tool runner
brew "pnpm"

# ═══ Language servers and linters ════════════════════════════════════════════
# These are owned by Homebrew, not by `go install` / rustup. Both gopls and
# rust-analyzer previously existed twice; PATH resolved to the brew copies.
brew "gopls"
brew "rust-analyzer"
brew "yaml-language-server"
brew "golangci-lint"          # moved here from `go install`
brew "biome"                  # moved here from npm global @biomejs/biome
brew "ast-grep"               # structural search/rewrite

# ═══ Cloud and infrastructure ════════════════════════════════════════════════
brew "azure-cli"
brew "doctl"                  # DigitalOcean
brew "helm"
brew "argocd"
brew "vercel"
brew "supabase"
brew "mole"                   # SSH tunnel manager
brew "mkcert"                 # locally-trusted dev certificates

# ═══ Databases ═══════════════════════════════════════════════════════════════
# postgresql@14 dropped: @15 supersedes it and both were installed.
brew "postgresql@15"
brew "redis"

# ═══ Language-specific tooling ═══════════════════════════════════════════════
brew "maven"                  # Java
brew "go-blueprint"           # Go project scaffolding

# ═══ Documents and media ═════════════════════════════════════════════════════
brew "pandoc"                 # markdown -> HTML/PDF
brew "poppler"                # pdftotext, pdfimages
brew "mas"                    # Mac App Store CLI

# ═══ Fonts ═══════════════════════════════════════════════════════════════════
# ADDED, not from your original list. This machine has no Nerd Font, only
# Menlo and Monaco. LazyVim's file tree, git signs and statusline draw glyphs
# from the Nerd Font private-use range, which render as empty boxes without
# one. Required by the LazyVim decision rather than a preference.
cask "font-jetbrains-mono-nerd-font"

# ═══ Casks ═══════════════════════════════════════════════════════════════════
cask "ghostty"                # primary terminal; config in ghostty/
cask "cursor"                 # ADDED: was installed manually, so nothing in
                              # the previous setup would reinstall it
cask "visual-studio-code"
cask "claude-code"
cask "codexbar"
cask "opencode-desktop"
cask "google-chrome"
cask "docker-desktop"
cask "raycast"
cask "rectangle"              # window management
cask "slack"
cask "gcloud-cli"
cask "ngrok"
cask "wispr-flow"             # voice dictation
cask "vlc"

# ═══ Not installed, on purpose ═══════════════════════════════════════════════
# postgresql@14   duplicate of @15
# sl              ASCII train joke package
# sshpass         password-based SSH; discouraged, and keys are in use
# msodbcsql18     MS SQL ODBC driver, no longer needed
# openai-whisper  heavy (pulls PyTorch); wispr-flow covers dictation
# volta           installed but managed nothing; Homebrew node is the single
#                 Node source, and zsh-nvm was removed from the zinit list
# mactex          ~6 GB LaTeX distribution
# libreoffice     large office suite
# warp            Ghostty is primary; Warp keeps config in its own app state
# textream
#
# air / benchstat / jscan stay as `go install` (setup/packages/go.txt). brew's
# `air` is version 0.11.0 while the Go live-reload tool is v1.x, so they are
# almost certainly different packages. Not swapped without verification.
