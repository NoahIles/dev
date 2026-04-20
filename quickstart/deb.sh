#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"
. "$SCRIPT_DIR/helpers.sh"

echo "Starting Debian/Ubuntu-based setup"

maybe_sudo apt-get update && maybe_sudo apt-get upgrade -y && maybe_sudo apt-get install -y fish

#fish -c fish_add_path ~/.local/bin/


