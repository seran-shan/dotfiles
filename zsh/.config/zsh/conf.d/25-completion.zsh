#!/bin/zsh
# Completion presentation. Must load after compinit (20-plugins.zsh).

# Case-insensitive matching: `cd doc` matches Documents.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Colour completion entries using the same palette as ls.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# No zsh menu; fzf-tab renders the picker instead.
zstyle ':completion:*' menu no

# Directory preview while completing `cd`. Uses eza if present (ls has no
# --color=always equivalent on macOS), falling back to plain ls.
if (( $+commands[eza] )); then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 $realpath'
fi
