#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"

echo "Starting Arch Based setup"

# Privilege Model: This script uses sudo for privileged commands.
# Run as a regular user - sudo will prompt for password if needed.
# Cache sudo credentials to avoid multiple password prompts
sudo -v

# Run paru installation script only if paru is not already installed
if ! command -v paru &> /dev/null; then
  bash "$SCRIPT_DIR/scripts/arch/paru.sh"
fi

paru -S --noconfirm --needed zen-browser-bin

