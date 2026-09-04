#!/bin/zsh
# Third-party shell integrations. Every one is guarded, so a fresh machine
# mid-bootstrap degrades quietly instead of erroring on every prompt.

# ── fzf ──────────────────────────────────────────────────────────────────────
(( $+commands[fzf] )) && source <(fzf --zsh)

# ── uv / uvx (Python tooling) ────────────────────────────────────────────────
(( $+commands[uv] ))  && eval "$(uv generate-shell-completion zsh)"
(( $+commands[uvx] )) && eval "$(uvx --generate-shell-completion zsh)"

# ── atuin (shell history) ────────────────────────────────────────────────────
# The zinit plugin in 20-plugins.zsh provides the binary; this activates it.
(( $+commands[atuin] )) && eval "$(atuin init zsh)"

# ── ngrok ────────────────────────────────────────────────────────────────────
(( $+commands[ngrok] )) && eval "$(ngrok completion)"

# ── bun ──────────────────────────────────────────────────────────────────────
# The previous config sourced /private/tmp/bun1313/_bun, a temp path wiped on
# every reboot, so bun completions were silently broken. Use the stable
# location, and only if bun has actually generated it (`bun completions`).
[[ -s "${BUN_INSTALL:-$HOME/.bun}/_bun" ]] && source "${BUN_INSTALL:-$HOME/.bun}/_bun"
