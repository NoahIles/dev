#!/bin/bash
# This is a Script to help redeploy//install Ubuntu env Essentials  
# 

# Update Ubuntu stuff 
sudo apt update && sudo apt upgrade 

# Install, enable, start SSH 
sudo apt install ssh
sudo systemctl enable --now ssh

# Misc Installation tools 
sudo apt install net-tools curl htop ncdu zsh git vim

#Oh-My-ZSH
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z

/bin/cp -rf .zshrc $HOME/.zshrc
/bin/cp -rf .vimrc $HOME/.vimrc


# Zerotier VPN Stuff
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
sudo zerotier-cli join 1c33c1ced03bb70c

# RDP/VNC stuff
sudo apt install xfce4 xfce4-goodies

# TODO: Add MC Server Stuff
sudo apt install screen openjdk-11-jre-headless default-jdk -y 
sudo ufw allow 25565


# TODO: Add Xrdp Stuff 