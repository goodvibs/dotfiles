#!/bin/sh
PLUGINS_BIN="${DOTFILES_PLUGINS_BIN:-$HOME/.local/share/dotfiles/plugins/bin}"

mkdir -p "$PLUGINS_BIN"
ln -sf "$HOME/Developer/Personal/git-open/git-open" "$PLUGINS_BIN/git-open"
