#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
  echo "❗ Error: This script must be run as root." >&2
  echo "Please run with sudo: sudo $0" >&2
  exit 1
fi

if command -v apt >/dev/null 2>&1; then
  apt-get update && apt-get install vim
else
    echo "❌ apt was not found."
    echo "This is likely not a Debian-based system (like Ubuntu, Mint, etc.)."
fi
# Copy config files 

cp -r ../env/.vim $HOME/
