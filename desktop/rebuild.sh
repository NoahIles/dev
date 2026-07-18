#!/usr/bin/env bash
# Rebuild NixOS from this flake, commit on success, and re-sync the kernel
# to the ESP if it changed (Limine boots a copy, not the store path).
# Run from a booted NixOS.
#
# Usage: rebuild.sh [--force] [commit subject] [body paragraph...]
#   With no args, commits as "rebuild: <generation>".
#   With args, the first is the commit subject and any extras become body
#   paragraphs; the generation line is appended as a trailing body paragraph.
#   --force: rebuild even if no *.nix changed (skips the commit steps then).

set -euo pipefail
cd "$(dirname "$0")"

force=0
if [ "${1:-}" = "--force" ]; then force=1; shift; fi
commit_args=("$@")

have_changes=1
if git diff --quiet -- '*.nix'; then
    if [ "$force" = 1 ]; then
        have_changes=0
    else
        echo "No changes detected, exiting."
        exit 0
    fi
fi

alejandra -q . || { echo "formatting failed!"; exit 1; }

git diff -U0 -- '*.nix'
git commit -av --allow-empty-message -m ""

echo "NixOS rebuilding..."
echo "nixos-rebuild switch --flake .#desktop"
sudo nixos-rebuild switch --flake .#desktop

# new kernel? Limine boots a copy on the ESP, not the store — re-sync.
# The ESP is root-only (fmask=0077) so we can't cmp against it directly;
# limine-sync.sh stamps the initrd store path it last synced instead.
if [ "$(readlink -f /run/current-system/initrd)" != "$(cat .limine-initrd-stamp 2>/dev/null)" ]; then
    echo "Kernel changed — syncing ESP..."
    sudo ./limine-sync.sh
    echo "Restart Recomended"
fi

gen="rebuild: $(nixos-rebuild list-generations 2>/dev/null | grep -w current || date -Iseconds)"
if [ ${#commit_args[@]} -gt 0 ]; then
    # first arg = subject, extras = body paragraphs, gen line appended as body
    msg_args=()
    for m in "${commit_args[@]}"; do msg_args+=(-m "$m"); done
    msg_args+=(-m "$gen")
    git commit --amend "${msg_args[@]}"
else
    git commit --amend -m "$gen"
fi

command -v notify-send >/dev/null && notify-send -e "NixOS rebuilt OK" || true
