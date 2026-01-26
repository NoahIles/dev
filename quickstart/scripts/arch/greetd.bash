#! /usr/bin/env bash

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

