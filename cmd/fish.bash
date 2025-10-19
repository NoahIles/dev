#! /usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
  echo "❗ Error: This script must be run as root." >&2
  echo "Please run with sudo: sudo $0" >&2
  exit 1
fi

if command -v apt >/dev/null 2>&1; then
  apt-get update && apt-get install fish
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
else
    echo "❌ apt was not found."
    echo "This is likely not a Debian-based system (like Ubuntu, Mint, etc.)."
fi

fisher install jhillyerd/plugin-git

if command -v docker >/dev/null 2>&1; then
  fisher install asim-tahir/docker-compose
fi
# download config

cp -r ../env/fish/* $HOME/.config/fish/

echo "source $HOME/.config/fish/essentials.fish" >> $HOME/.config/fish/config.fish

