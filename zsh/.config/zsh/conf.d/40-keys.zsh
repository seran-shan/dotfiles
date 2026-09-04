#!/bin/zsh
# Key bindings. Carried over from the previous config.
#
# NOTE: zsh-vi-mode (loaded in 20-plugins.zsh) resets the keymap when it
# initialises, discarding bindings made before that point. Its documented
# escape hatch is the `zvm_after_init_commands` array, which it runs once
# initialisation finishes; bindings registered there survive.

_user_keybindings() {
  bindkey '^p' history-search-backward   # Ctrl-P: previous match for typed prefix
  bindkey '^n' history-search-forward    # Ctrl-N: next match
  bindkey '^[w' kill-region              # Alt-W: cut the selected region
}

# `${+name}` tests parameter existence; zsh-vi-mode declares this array when
# sourced. Using $+functions[] here would be wrong; it is not a function.
if (( ${+zvm_after_init_commands} )); then
  zvm_after_init_commands+=(_user_keybindings)
else
  _user_keybindings   # zsh-vi-mode absent, bind immediately
fi
