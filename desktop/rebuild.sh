#!/usr/bin/env bash
# Rebuild NixOS from this flake, commit on success.
# The Limine bootloader module handles ESP sync automatically.
#
# Usage: rebuild.sh [--force] [commit subject] [body paragraph...]
#   With no args, commits as "rebuild: <generation>".
#   With args, the first is the commit subject and any extras become body
#   paragraphs; the generation line and nvd diff are appended to the body.
#   --force: rebuild even if no *.nix changed (skips the commit steps then).
#
# ponytail: nothing is staged before the rebuild — nix reads tracked files
# straight from a dirty working tree. New files stay untracked (and so
# invisible to the flake) until you `git add` them yourself, on purpose.

set -euo pipefail
cd "$(dirname "$0")"

force=0
if [ "${1:-}" = "--force" ]; then force=1; shift; fi
commit_args=("$@")

commit=1
if git diff HEAD --quiet -- '*.nix' '*.lock'; then
    [ "$force" = 1 ] || { echo "No changes detected, exiting."; exit 0; }
    commit=0
fi

alejandra -q . || { echo "formatting failed!"; exit 1; }

git diff HEAD -U0 -- '*.nix'

echo "NixOS rebuilding..."
nixos-rebuild build --flake .#desktop
system_path="$(readlink -f result)"

nvd_out="$(nvd diff /run/current-system result)"
printf '%s\n' "$nvd_out"

sudo nixos-rebuild switch --no-reexec --store-path "$system_path"

if [ "$commit" = 1 ]; then
    gen="rebuild: $(nixos-rebuild list-generations 2>/dev/null | grep -w current || date -Iseconds)"

    {
        [ ${#commit_args[@]} -eq 0 ] || printf '%s\n\n' "${commit_args[@]}"
        printf '%s\n\nnvd diff:\n\n```text\n%s\n```\n' "$gen" "$nvd_out"
    } | git commit -a --cleanup=verbatim -F -
fi

command -v notify-send >/dev/null && notify-send -e "NixOS rebuilt OK" || true
