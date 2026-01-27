#! /usr/bin/env bash
set -euo pipefail

# Privilege Model: This script uses sudo for privileged commands.
# Run as a regular user - sudo will prompt for password if needed.
# Cache sudo credentials to avoid multiple password prompts
sudo -v

# Dependecy for Mason/nvim
sudo pacman --needed --noconfirm -S npm neovim

