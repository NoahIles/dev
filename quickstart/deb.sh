#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"

# Privilege Model: Scripts called from here use sudo for privileged commands.
# Run as a regular user - sudo will prompt for password if needed.

echo "Starting Debian/Ubuntu-based setup"
