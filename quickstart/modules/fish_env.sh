#! /usr/bin/env bash

# 1. Get the script's directory, resolving any symlinks and ensuring an absolute path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname $(dirname "$SCRIPT_DIR"))"

#TODO: Make this idempotent
cp -r $PARENT_DIR/env/fish/* $HOME/.config/fish/
echo "source $HOME/.config/fish/essentials.fish" >> $HOME/.config/fish/config.fish
