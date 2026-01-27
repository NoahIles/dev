#! /usr/bin/env bash
set -euo pipefail

# Privilege Model: This script uses sudo for privileged commands.
# Run as a regular user - sudo will prompt for password if needed.
# Cache sudo credentials to avoid multiple password prompts
sudo -v

sudo pacman -Syu

# Copy fish config
# This should call another script 

sudo pacman -S --noconfirm --needed fish gcc bat eza zoxide starship fastfetch wl-clipboard tealdeer fzf

chsh -s $(which fish)
