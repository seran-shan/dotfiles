#!/bin/zsh
# ~/.zshrc: thin loader. All real configuration lives in conf.d/, sourced in
# numeric order. Add a new concern as a new numbered file; never grow this one.

# Homebrew must come first: every conf.d module below assumes brew binaries
# are on PATH. Apple Silicon and Intel prefixes both handled.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

ZSH_CONFIG_DIR="${HOME}/.config/zsh"

# The (N) glob qualifier is required: without it, an empty or missing conf.d
# makes zsh abort with "no matches found" instead of skipping silently.
for _zsh_module in "${ZSH_CONFIG_DIR}"/conf.d/*.zsh(N); do
  source "${_zsh_module}"
done
unset _zsh_module

# Machine-local overrides, last so they win. Gitignored; see setup/zshrc.local.example.
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
