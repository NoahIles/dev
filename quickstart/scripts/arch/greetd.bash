#! /usr/bin/env bash
set -euo pipefail

# Privilege Model: This script uses sudo for privileged commands.
# Run as a regular user - sudo will prompt for password if needed.
# Cache sudo credentials to avoid multiple password prompts
sudo -v

# Sets up the login screen baby
#
install () {
    sudo pacman --noconfirm --needed -S greetd-tuigreet
}

# Substitute command line to use tuigreet

configure () {
echo "Installing tuigreet to /etc/greetd/config.toml"
TUI_GREET='tuigreet -rt --cmd hyprland --asterisks'
sudo sed -i "s/command .*/command = ${TUI_GREET}/" /etc/greetd/config.toml
}

services () {
echo "Configuring systemd services \n Enabling greetd service"
sudo systemctl enable greetd
echo "disabling sddm" 
sudo systemctl disable sddm
}


install
configure
services

