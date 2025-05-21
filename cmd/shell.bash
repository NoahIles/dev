#! /usr/bin/env bash

set -o pipefail

sudo pacman -Syu

# Copy fish config
# This should call another script 

sudo pacman -S --noconfirm --needed fish gcc bat eza zoxide starship fastfetch wl-clipboard tealdeer fzf

chsh -s $(which fish)
