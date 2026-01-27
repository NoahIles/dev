#! /usr/bin/env bash
set -euo pipefail

# 1. Get the script's directory, resolving any symlinks and ensuring an absolute path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname $(dirname "$SCRIPT_DIR"))"

# Idempotency: Check if module has already been run
STATE_DIR="$HOME/.config/dev-setup/modules"
MARKER_FILE="$STATE_DIR/fish_env.done"

if [ -f "$MARKER_FILE" ]; then
    echo "fish_env module already completed, skipping..."
    exit 0
fi

# Copy fish configuration files
cp -r $PARENT_DIR/env/fish/* $HOME/.config/fish/

# Idempotency: Check if essentials.fish source line already exists in config.fish
CONFIG_FILE="$HOME/.config/fish/config.fish"
SOURCE_LINE="source $HOME/.config/fish/essentials.fish"

if ! grep -qF "$SOURCE_LINE" "$CONFIG_FILE" 2>/dev/null; then
    echo "$SOURCE_LINE" >> "$CONFIG_FILE"
fi

# Create marker file to indicate completion
mkdir -p "$STATE_DIR"
touch "$MARKER_FILE"
