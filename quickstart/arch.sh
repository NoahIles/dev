#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"

echo "Starting Arch Based setup"

# Privilege Model: Run privileged commands directly if already root or sudo is
# unavailable; otherwise prefix with sudo.
maybe_sudo() {
  if [ "$(id -u)" -eq 0 ] || ! command -v sudo &> /dev/null; then
    "$@"
  else
    sudo "$@"
  fi
}

# Cache sudo credentials upfront (skipped when running as root or without sudo)
if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
  sudo -v
fi

# Run paru installation script only if paru is not already installed
if ! command -v paru &> /dev/null; then
  bash "$SCRIPT_DIR/scripts/arch/paru.sh"
fi

paru -S --noconfirm --needed zen-browser-bin

