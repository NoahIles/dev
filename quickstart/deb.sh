#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"

# Privilege Model: Run privileged commands directly if already root or sudo is
# unavailable; otherwise prefix with sudo.
maybe_sudo() {
  if [ "$(id -u)" -eq 0 ] || ! command -v sudo &> /dev/null; then
    "$@"
  else
    sudo "$@"
  fi
}

echo "Starting Debian/Ubuntu-based setup"

maybe_sudo apt-get update && maybe_sudo apt upgrade -y && maybe_sudo apt install -y fish

#fish -c fish_add_path ~/.local/bin/


