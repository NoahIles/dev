#!/usr/bin/env bash
# One-shot: move ~/.config into a new top-level @config btrfs subvolume.
# Run as root from a TTY with the graphical session logged OUT.
set -euo pipefail
DEV=/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702
CFG=/home/noah/.config
MNT=$(mktemp -d)

[ "$(id -u)" = 0 ] || { echo "run as root (sudo/pkexec)"; exit 1; }
if fuser -m "$CFG" >/dev/null 2>&1; then
    echo "processes still using $CFG — log out of the session first:"
    fuser -vm "$CFG" || true
    exit 1
fi

mount -o subvol=/ "$DEV" "$MNT"
trap 'umount "$MNT" && rmdir "$MNT"' EXIT
[ -e "$MNT/@config" ] && { echo "@config already exists, aborting"; exit 1; }

btrfs subvolume create "$MNT/@config"
echo "copying (reflink, fast)..."
cp -a --reflink=always "$CFG/." "$MNT/@config/"
chown noah:users "$MNT/@config"

src=$(find "$CFG" | wc -l); dst=$(find "$MNT/@config" | wc -l)
[ "$src" = "$dst" ] || { echo "file count mismatch ($src vs $dst), aborting before delete"; exit 1; }

find "$CFG" -mindepth 1 -delete
mount -o subvol=@config,noatime,compress=zstd:3,discard=async,commit=120 "$DEV" "$CFG"
echo "OK: @config created and mounted at $CFG."
echo "Next: rebuild with the fileSystems entry, then add the CachyOS fstab line."
