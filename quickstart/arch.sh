#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"
. "$SCRIPT_DIR/helpers.sh"

echo "Starting Arch Based setup"

maybe_sudo true

# Run paru installation script only if paru is not already installed
if ! command -v paru &> /dev/null; then
  bash "$SCRIPT_DIR/scripts/arch/paru.sh"
fi

paru -S --noconfirm --needed zen-browser-bin

