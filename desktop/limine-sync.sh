#!/usr/bin/env bash
# Sync the NixOS kernel/initrd to the ESP, sign the kernel with sbctl, and
# maintain the /+NixOS entry in /boot/limine.conf. Run as root.
#
# Works from CachyOS (pass the target root, e.g. /mnt/nixos) or from a booted
# NixOS (no argument — uses /). Re-run after any NixOS kernel version bump;
# ordinary rebuilds don't need it (cmdline init= follows the system profile).
set -euo pipefail

TARGET_ROOT="${1:-/}"
PROFILE="$TARGET_ROOT/nix/var/nix/profiles/system"
ESP=/boot
CONF="$ESP/limine.conf"
ROOT_UUID=288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702

[ -f "$CONF" ] || { echo "no $CONF" >&2; exit 1; }

# resolve symlinks *within* TARGET_ROOT (absolute link targets point inside
# the target's /nix, which doesn't exist on the host when run from CachyOS)
resolve() {
  local p="$1" t
  while t=$(readlink "$p" 2>/dev/null); do
    case "$t" in
      /*) p="${TARGET_ROOT%/}$t" ;;
      *) p="$(dirname "$p")/$t" ;;
    esac
  done
  echo "$p"
}

SYSDIR=$(resolve "$PROFILE")
KERNEL=$(resolve "$SYSDIR/kernel")
INITRD=$(resolve "$SYSDIR/initrd")
[ -f "$KERNEL" ] || { echo "no kernel at $PROFILE" >&2; exit 1; }

mkdir -p "$ESP/nixos"
cp -f "$KERNEL" "$ESP/nixos/bzImage"
cp -f "$INITRD" "$ESP/nixos/initrd"
sbctl sign -s "$ESP/nixos/bzImage"

KHASH=$(b2sum "$ESP/nixos/bzImage" | cut -d' ' -f1)
IHASH=$(b2sum "$ESP/nixos/initrd" | cut -d' ' -f1)

cp -f "$CONF" "$CONF.nixos-bak"
# drop existing marked block (everything from marker to EOF — block is
# always kept last so existing entry indices / default_entry stay stable)
sed -i '/^### BEGIN nixos limine-sync/,$d' "$CONF"

cat >> "$CONF" <<EOF
### BEGIN nixos limine-sync (managed by limine-sync.sh — keep last)
/+NixOS
    protocol: linux
    path: boot():/nixos/bzImage#$KHASH
    module_path: boot():/nixos/initrd#$IHASH
    cmdline: init=/nix/var/nix/profiles/system/init root=UUID=$ROOT_UUID rootflags=subvol=@nixos rw
EOF

echo "limine.conf updated (backup: $CONF.nixos-bak)"
