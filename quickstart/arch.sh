#! /usr/bin/env bash

echo "Starting Arch Based setup"

if [ "$(id -u)" -ne 0 ]; then
  echo "❗ Error: This script must be run as root." >&2
  echo "Please run with sudo: sudo $0" >&2
  exit 1
fi

$SCRIPT_DIR/cmd/paru.sh

paru -S --noconfirm --needed zen-browser-bin

