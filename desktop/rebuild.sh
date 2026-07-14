#!/usr/bin/env bash
# Rebuild NixOS from this flake, commit on success, and re-sync the kernel
# to the ESP if it changed (Limine boots a copy, not the store path).
# Run from a booted NixOS.
#
# Usage: rebuild.sh [commit subject] [body paragraph...]
#   With no args, commits as "rebuild: <generation>".
#   With args, the first is the commit subject and any extras become body
#   paragraphs; the generation line is appended as a trailing body paragraph.
set -euo pipefail
cd "$(dirname "$0")"

commit_args=("$@")

if git diff --quiet -- '*.nix'; then
    echo "No changes detected, exiting."
    exit 0
fi

alejandra -q . || { echo "formatting failed!"; exit 1; }

git diff -U0 -- '*.nix'

echo "NixOS rebuilding..."
sudo nixos-rebuild switch --flake .#desktop

# new kernel? Limine boots a copy on the ESP, not the store — re-sync.
# (compare initrd: the ESP kernel is sbctl-signed so it never byte-matches)
if ! cmp -s /run/current-system/initrd /boot/nixos/initrd 2>/dev/null; then
    echo "Kernel changed — syncing ESP..."
    sudo ./limine-sync.sh
fi

gen="rebuild: $(nixos-rebuild list-generations 2>/dev/null | grep -w current || date -Iseconds)"
if [ ${#commit_args[@]} -gt 0 ]; then
    # first arg = subject, extras = body paragraphs, gen line appended as body
    msg_args=()
    for m in "${commit_args[@]}"; do msg_args+=(-m "$m"); done
    msg_args+=(-m "$gen")
    git commit -a "${msg_args[@]}"
else
    git commit -am "$gen"
fi

command -v notify-send >/dev/null && notify-send -e "NixOS rebuilt OK" || true
