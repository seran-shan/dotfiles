#!/bin/zsh
# Aliases. Kept short.
#
# The previous config carried 15 aliases; you chose to start fresh. Several
# were pointing at things that no longer worked:
#   gitui -> lazygit          duplicated the broken `git ui` git alias
#   tf    -> terraform        terraform is not installed
#   speedtest -> speedtest-cli  speedtest-cli is not installed
#   cd..  -> cd ..            superseded by setopt auto_cd (10-options.zsh)
#
# Add back only what you actually miss. Each alias is guarded so a missing
# tool degrades to the real command instead of shadowing it with an error.

# ── Modern replacements, only if installed ───────────────────────────────────
(( $+commands[eza] )) && {
  alias ls='eza --group-directories-first'
  alias ll='eza --long --group-directories-first --git'
  alias la='eza --long --all --group-directories-first --git'
  alias tree='eza --tree --level=2'
}

(( $+commands[bat] )) && alias cat='bat --paging=never'

# ── Tools you actually invoke ────────────────────────────────────────────────
(( $+commands[lazygit] )) && alias lg='lazygit'

# omo is your agent CLI, not a convenience alias. Kept as a launcher.
[[ -x "${HOME}/.cmuxterm/omo" ]] && alias omo="${HOME}/.cmuxterm/omo"

# ── Dotfiles ─────────────────────────────────────────────────────────────────
# `dot` jumps to the repo so `just` recipes are always one step away.
alias dot='cd ~/dotfiles'
