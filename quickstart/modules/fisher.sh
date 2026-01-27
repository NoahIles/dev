#! /usr/bin/env bash
set -euo pipefail

# Check if Fish shell is installed
if ! command -v fish >/dev/null 2>&1; then
    echo "Error: Fish shell is not installed. Please install Fish before running this module."
    exit 1
fi

# Idempotency: Check if module has already been run
STATE_DIR="$HOME/.config/dev-setup/modules"
MARKER_FILE="$STATE_DIR/fisher.done"

if [ -f "$MARKER_FILE" ]; then
    echo "fisher module already completed, skipping..."
    exit 0
fi

# Install Fisher plugin manager using the official installation method
echo "Installing Fisher plugin manager..."
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

# Install Fisher plugins
echo "Installing Fisher plugins..."
fish -c "fisher install jhillyerd/plugin-git"

if command -v docker >/dev/null 2>&1; then
    echo "Docker detected, installing docker-compose plugin..."
    fish -c "fisher install asim-tahir/docker-compose"
fi

# Create marker file to indicate completion
mkdir -p "$STATE_DIR"
touch "$MARKER_FILE"
echo "Fisher installation completed successfully."