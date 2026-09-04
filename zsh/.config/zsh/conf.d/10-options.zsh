#!/bin/zsh
# Shell behaviour and history. Carried over verbatim from the previous config.

# ── History ──────────────────────────────────────────────────────────────────
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt append_history          # append rather than overwrite on exit
setopt share_history           # share history live between open shells
setopt hist_ignore_space       # a leading space keeps a command out of history
setopt hist_ignore_all_dups    # drop older duplicates of a repeated command
setopt hist_save_no_dups       # never write duplicates to the history file
setopt hist_ignore_dups        # skip a command identical to the previous one
setopt hist_find_no_dups       # searching skips duplicates

# ── Directory navigation ─────────────────────────────────────────────────────
setopt auto_cd                 # `..` alone changes directory
setopt auto_pushd              # every cd pushes onto the directory stack
setopt pushd_ignore_dups
setopt pushd_silent

# ── Correctness and safety ───────────────────────────────────────────────────
setopt interactive_comments    # allow `# comment` when typing interactively
setopt no_clobber              # `>` refuses to truncate an existing file; use >|
setopt no_beep
