#!/usr/bin/env bash
#
# macOS system preferences.
#
# Never runs automatically. Run it with `just macos`.
# Every setting here was individually approved; nothing was added beyond that
# list. See the "Not set" note at the bottom.
#
# Reversing any of these: swap `-bool true` for `-bool false` (or use
# `defaults delete <domain> <key>` to restore the system default), then log out.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Not macOS, nothing to do." >&2
  exit 0
fi

echo "Applying macOS defaults…"

# Ask for the admin password up front, then keep the sudo timestamp alive until
# this script exits. Avoids a password prompt appearing midway through.
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ─── Finder ──────────────────────────────────────────────────────────────────

# Always show file extensions. Hidden extensions make ".pdf.app" style
# disguises possible, so this is a mild security win as well as a clarity one.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show dotfiles in Finder. Directly relevant now that you manage them.
defaults write com.apple.finder AppleShowAllFiles -bool true

# Path bar along the bottom of every Finder window.
defaults write com.apple.finder ShowPathbar -bool true

# Search the current folder by default instead of the whole Mac.
# SCcf = "current folder"; the macOS default SCev = "this Mac".
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Do not litter network shares and USB drives with .DS_Store files.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ─── Keyboard ────────────────────────────────────────────────────────────────

# Fast key repeat. KeyRepeat is the interval between repeats and
# InitialKeyRepeat the delay before the first one; both are in units of 15ms.
# System Settings cannot go this low. Matters for zsh-vi-mode and Neovim,
# where holding j/k to move is routine.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Holding a key repeats it instead of opening the accent picker.
# Without this, holding `j` in Neovim shows a diacritic menu rather than moving.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ─── Screenshots ─────────────────────────────────────────────────────────────

# Keep screenshots out of the Desktop.
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Drop the window drop-shadow, which otherwise adds transparent padding.
defaults write com.apple.screencapture disable-shadow -bool true

# ─── Dock ────────────────────────────────────────────────────────────────────

# Remove the delay before an auto-hidden Dock appears.
defaults write com.apple.dock autohide-delay -float 0

# ─── Application lifecycle ───────────────────────────────────────────────────

# Stop macOS silently quitting apps it decides are idle.
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# ─── Apply ───────────────────────────────────────────────────────────────────
# Restart the affected apps so changes take effect without a full logout.
for app in Finder Dock SystemUIServer; do
  killall "${app}" >/dev/null 2>&1 || true
done

echo
echo "Done. Some settings only apply fully after a logout."
echo
echo "Not set (excluded during review):"
echo "  • Finder default list view (FXPreferredViewStyle = Nlsv)"
