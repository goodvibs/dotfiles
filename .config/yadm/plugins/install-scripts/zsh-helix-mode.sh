#!/bin/sh
# install-scripts/ lives one level below the plugins directory.
PLUGINS_SRC="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS_BIN="${DOTFILES_PLUGINS_BIN:-$HOME/.local/share/dotfiles/plugins/bin}"
ZSH_HELIX_MODE_DIR="${ZSH_HELIX_MODE_DIR:-$HOME/Developer/Personal/zsh-helix-mode}"

mkdir -p "$PLUGINS_BIN"

if [ ! -d "$ZSH_HELIX_MODE_DIR/.git" ]; then
  git clone https://github.com/Multirious/zsh-helix-mode --depth 1 "$ZSH_HELIX_MODE_DIR"
fi

ln -sf "$PLUGINS_SRC/zsh-helix-mode.zsh" "$PLUGINS_BIN/zsh-helix-mode"
