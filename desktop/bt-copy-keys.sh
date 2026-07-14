#!/usr/bin/env bash
# One-off: copy Bluetooth pairing keys from CachyOS (same btrfs, other
# subvolume) into this NixOS install, so devices paired there — e.g. the
# Magic Keyboard — connect here without re-pairing. Run as root, then delete.
set -euo pipefail

FSUUID=288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702
TOP=$(mktemp -d)
mount -o subvol=/,ro "/dev/disk/by-uuid/$FSUUID" "$TOP"
trap 'umount "$TOP" && rmdir "$TOP"' EXIT

# find the CachyOS subvolume: any top-level subvol (other than @nixos)
# that has a populated /var/lib/bluetooth
src=""
for d in "$TOP"/*/var/lib/bluetooth; do
    [[ $d == *"/@nixos/"* ]] && continue
    [[ -d $d ]] && compgen -G "$d/*:*" >/dev/null && { src=$d; break; }
done
[[ -n $src ]] || { echo "No bluetooth state found on other subvolumes"; exit 1; }
echo "Found CachyOS bluetooth state: $src"

systemctl stop bluetooth
for adapter in "$src"/*:*; do
    mac=$(basename "$adapter")
    mkdir -p "/var/lib/bluetooth/$mac"
    # copy device dirs (pairing keys) but keep NixOS's own adapter settings
    for dev in "$adapter"/*:*; do
        [[ -d $dev ]] || continue
        echo "  copying device $(basename "$dev") -> adapter $mac"
        cp -a "$dev" "/var/lib/bluetooth/$mac/"
    done
done
systemctl start bluetooth
echo "Done. Devices paired on CachyOS should now connect here."
