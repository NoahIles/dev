#! /usr/bin/env bash
set -euo pipefail

# Privilege Model: This script uses sudo for privileged commands.
# Run as a regular user - sudo will prompt for password if needed.
# Cache sudo credentials to avoid multiple password prompts
sudo -v

sudo pacman -S --noconfirm --needed podman-docker podman-compose
