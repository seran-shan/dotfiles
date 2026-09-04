#!/bin/zsh
# PATH and core environment. Loaded first; everything after this assumes it.

# ── PATH hygiene ─────────────────────────────────────────────────────────────
# zsh keeps $path and $PATH bound to each other. `typeset -U path` makes the
# array unique, so re-sourcing this file (or a duplicated entry anywhere) can
# never produce the doubled PATH the previous config had.
typeset -U path PATH

# prepend() adds a directory only if it actually exists. Dead entries were a
# real problem before: two LM Studio paths were being exported that no longer
# exist on disk.
_prepend_path() { [[ -d "$1" ]] && path=("$1" $path) }
_append_path()  { [[ -d "$1" ]] && path=($path "$1") }

# ── Language toolchains ──────────────────────────────────────────────────────
export PNPM_HOME="${HOME}/Library/pnpm"
_prepend_path "$PNPM_HOME"

export JAVA_HOME=/opt/homebrew/opt/openjdk
_prepend_path "/opt/homebrew/opt/openjdk/bin"

# ── Cloud and infrastructure ─────────────────────────────────────────────────
_prepend_path "/opt/homebrew/share/google-cloud-sdk/bin"
_prepend_path "/usr/local/keycloak-26.3.3/bin"

# ── AI tooling ───────────────────────────────────────────────────────────────
_prepend_path "${HOME}/.antigravity/antigravity/bin"
_prepend_path "${HOME}/.opencode/bin"

# ── User binaries: last prepend wins, so this sits ahead of the rest ─────────
_prepend_path "${HOME}/.local/bin"

unset -f _prepend_path _append_path

# ── Editor ───────────────────────────────────────────────────────────────────
# `$+commands[x]` is a zsh builtin table lookup. The previous config used
# EDITOR="$(which cursor)", which forked a subshell on every single shell start.
if (( $+commands[cursor] )); then
  export EDITOR=cursor
elif (( $+commands[nvim] )); then
  export EDITOR=nvim
else
  export EDITOR=vi
fi
export VISUAL="$EDITOR"

# ── Locale ───────────────────────────────────────────────────────────────────
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
