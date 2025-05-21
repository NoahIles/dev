#! /usr/bin/env bash

sudo pacman -S --needed --noconfirm base-devel rustup

rustup default stable

git clone https://aur.archlinux.org/paru.git ~/.cache/paru
cd ~/.cache/paru
makepkg -si
