#!/usr/bin/env bash
# Rebuild NixOS from this flake, recording each generation in git.
# The Limine bootloader module handles ESP sync automatically.
#
# Usage: rebuild.sh [--force] [commit subject] [body paragraph...]
#   Commits pending work FIRST (so the generation records an exact rev via
#   system.configurationRevision), then builds, switches, and tags the built
#   commit "gen-N" (annotated: the tag message holds the shortlog and nvd diff).
#   `just gens` lists them.
#   With no args the work commit is "wip: <timestamp>", meant to be rewritten.
#   Runs on a clean tree too, as long as HEAD moved since the last rebuild —
#   that's the manual-commit workflow.
#   --force: rebuild regardless, and don't touch git at all.
#
# See docs/adr/0003-gen-tags.md (supersedes 0001).
#
# ponytail: nothing is staged for you — `git commit -a` only sweeps tracked
# files. New files stay untracked (and so invisible to the flake) until you
# `git add` them yourself, on purpose.

set -euo pipefail
cd "$(dirname "$0")"

force=0
if [ "${1:-}" = "--force" ]; then force=1; shift; fi

# Before any dirty check, so there is only one post-format state to reason about.
alejandra -q . || { echo "formatting failed!"; exit 1; }

# Nix computes dirtiness over the whole tree, so any tracked change counts.
dirty=0
git diff HEAD --quiet || dirty=1
# Newest gen tag overall, not just reachable ones: after a squash the last
# build's commit is off-branch but still what's running.
last_tag="$(git tag -l 'gen-*' --sort=-v:refname | head -1)"
last_rebuild="$([ -z "$last_tag" ] || git rev-parse "$last_tag^{commit}")"

if [ "$force" = 0 ] && [ "$dirty" = 0 ] && [ "$(git rev-parse HEAD)" = "$last_rebuild" ]; then
    echo "Nothing to rebuild."
    exit 0
fi

# Print Git Diff and create WIP commit
committed=0
if [ "$force" = 0 ] && [ "$dirty" = 1 ]; then
    git diff HEAD -U0
    subject="${1:-wip: $(date -Iseconds)}"
    [ $# -eq 0 ] || shift
    printf '%s\n\n' "$subject" "$@" | git commit -a --cleanup=verbatim -F -
    committed=1
fi

# Attempt build if build fails reset 1 soft
echo "NixOS rebuilding..."
build_start=$SECONDS
# Under gamemode for the performance governor (system-wide, so the daemon builders get it too).
gamemoderun nixos-rebuild build --flake .#NixIsland --log-format internal-json -v 2>&1 |
    nom --json ||
    { [ "$committed" = 0 ] || git reset --soft HEAD~1; exit 1; }
build_secs=$((SECONDS - build_start))
printf '\nBuild time: %dm%02ds\n' $((build_secs / 60)) $((build_secs % 60))

system_path="$(readlink -f result)"

# Captured output isn't a tty, so force colour on and strip it for the commit.
nvd_out="$(nvd --color=always diff /run/current-system result)"
printf '%s\n' "$nvd_out"

# A failed switch keeps the work commit: it built, so it belongs on the branch.
sudo nixos-rebuild switch --no-reexec --store-path "$system_path"

# ponytail: the switch restarts polkitd, and an agent's registration dies with
# it — soteria keeps running but can no longer prompt, so pkexec just fails.
systemctl --user restart polkit-soteria.service || true
# The polkit policy whitelists the *new* gamemode store path; a gamemoded left
# running from the old one gets a password prompt for every pkexec helper.
# ponytail: restarts even when the path didn't change; drops a running game's
# registration if you rebuild mid-game.
systemctl --user try-restart gamemoded.service || true

if [ "$force" = 0 ]; then
    gen="$(readlink /nix/var/nix/profiles/system | tr -dc 0-9)"
    {
        printf 'gen %s\n\n' "$gen"
        [ -z "$last_rebuild" ] || git log --oneline "$last_rebuild"..HEAD | sed 's/^/    /'
        printf '\nnvd diff:\n\n```text\n%s\n```\n' "$(sed 's/\x1b\[[0-9;]*m//g' <<<"$nvd_out")"
    } | git tag -a "gen-$gen" --cleanup=verbatim -F -
fi

command -v notify-send >/dev/null && notify-send -e "NixOS rebuilt OK" || true
