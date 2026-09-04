#!/bin/zsh
# zinit plugin manager plus the plugin set.
#
# ORDERING IS LOAD-BEARING and must stay inside this one file:
#   plugins -> compinit -> zinit cdreplay
# fzf-tab and zsh-completions register completion definitions that compinit
# has to compile; cdreplay then replays the compdef calls zinit deferred.
# Splitting these across files would reintroduce ordering bugs.

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Self-bootstrap on a fresh machine.
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins ──────────────────────────────────────────────────────────────────
zinit light zsh-users/zsh-syntax-highlighting   # commands colour green/red as typed
zinit light zsh-users/zsh-completions           # extra completion definitions
zinit light zsh-users/zsh-autosuggestions       # inline greyed suggestion from history
zinit light Aloxaf/fzf-tab                      # tab completion becomes an fzf picker
zinit light paulirish/git-open                  # `git open` opens the repo in a browser
zinit ice depth=1; zinit light jeffreytse/zsh-vi-mode
zinit load atuinsh/atuin                        # searchable shell history

# REMOVED: lukechilds/zsh-nvm.
# It created ~/.nvm but never provided the active node; Homebrew's node is
# what actually runs. Keeping it meant three Node managers, two of them dead.

# ── Oh-My-Zsh snippets ───────────────────────────────────────────────────────
zinit snippet OMZP::git                 # git aliases
zinit snippet OMZP::sudo                # ESC ESC prepends sudo to the current line
zinit snippet OMZP::command-not-found   # "did you mean" hints

# ── Completion system ────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zinit cdreplay -q
