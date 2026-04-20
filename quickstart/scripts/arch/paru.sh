#! /usr/bin/env bash
set -euo pipefail

. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../helpers.sh"

maybe_sudo true
maybe_sudo pacman -S --needed --noconfirm base-devel rustup

rustup default stable

git clone https://aur.archlinux.org/paru.git ~/.cache/paru
cd ~/.cache/paru
makepkg -si
