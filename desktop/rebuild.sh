#!/usr/bin/env bash
# Rebuild NixOS from this flake, commit on success.
# The Limine bootloader module handles ESP sync automatically.
#
# Usage: rebuild.sh [--force] [commit subject] [body paragraph...]
#   With no args, commits as "rebuild: <generation>".
#   With args, the first is the commit subject and any extras become body
#   paragraphs; the generation line and nvd diff are appended to the body.
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
if [ "$have_changes" = 1 ]; then
    git commit -av --allow-empty-message -m ""
fi

echo "NixOS rebuilding..."
sudo nixos-rebuild build --flake .#desktop
system_path="$(readlink -f result)"

nvd_output="$(mktemp)"
commit_message="$(mktemp)"
trap 'rm -f "$nvd_output" "$commit_message"' EXIT

nvd diff /run/current-system result | tee "$nvd_output"

sudo nixos-rebuild switch --no-reexec --store-path "$system_path"

if [ "$have_changes" = 1 ]; then
    gen="rebuild: $(nixos-rebuild list-generations 2>/dev/null | grep -w current || date -Iseconds)"

    if [ ${#commit_args[@]} -gt 0 ]; then
        printf '%s\n' "${commit_args[0]}" >"$commit_message"
        for body in "${commit_args[@]:1}"; do
            printf '\n%s\n' "$body" >>"$commit_message"
        done
        printf '\n%s\n' "$gen" >>"$commit_message"
    else
        printf '%s\n' "$gen" >"$commit_message"
    fi

    {
        printf '\nnvd diff:\n\n'
        printf '```text\n'
        cat "$nvd_output"
        printf '\n```\n'
    } >>"$commit_message"

    git commit --amend --cleanup=verbatim -F "$commit_message"
fi

command -v notify-send >/dev/null && notify-send -e "NixOS rebuilt OK" || true
