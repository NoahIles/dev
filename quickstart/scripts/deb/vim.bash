#!/usr/bin/env bash
set -euo pipefail

# Privilege Model: This script uses sudo for privileged commands.
# Run as a regular user - sudo will prompt for password if needed.
# Cache sudo credentials to avoid multiple password prompts
sudo -v

if command -v apt >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install vim
else
    echo "❌ apt was not found."
    echo "This is likely not a Debian-based system (like Ubuntu, Mint, etc.)."
fi
# Copy config files 

cp -r ../env/.vim $HOME/
