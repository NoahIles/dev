# nixos flake config

Personal NixOS config flake, forked from vimjoyer's flake-starter-config.
Each top-level folder is a self-contained config profile.

## Layout

- `flake.nix` — template registry (one template per profile folder)
- `desktop/` — **bare-metal desktop**: niri + noctalia, dual-boot with
  CachyOS on the same btrfs, `@home` shared. HM installs packages only and
  manages no files — `~/.config` on the shared home stays canonical.

## Install on real hardware (dual-boot, shared @home)

Installed **from within CachyOS** (no ISO boot needed — nix daemon builds the
closure) into the `@nixos` subvolume, `@home` shared. NixOS installs **no
bootloader**: CachyOS's Limine boots it, which keeps Secure Boot happy
(kernel signed with the existing sbctl keys; Limine entries don't need
signed chainloads).

```bash
# subvol + mounts
btrfs subvolume create <btrfs-root>/@nixos
mount @nixos -> /mnt/nixos, @home -> /mnt/nixos/home, ESP -> /mnt/nixos/boot
# install (no bootloader; grub explicitly disabled in configuration.nix)
nixos-install --root /mnt/nixos --no-root-passwd --flake ./desktop#desktop
cp -a /var/lib/sbctl /mnt/nixos/var/lib/   # so NixOS can sign kernels too
# copy+sign kernel to ESP, write /+NixOS limine.conf entry
./desktop/limine-sync.sh /mnt/nixos
```

`limine-sync.sh` keeps the Limine entry pointing at `boot():/nixos/bzImage`
with blake2b hashes, cmdline `init=/nix/var/nix/profiles/system/init` — so
ordinary `nixos-rebuild switch` needs nothing, only **kernel version bumps**
need a re-run (from NixOS: `sudo ./limine-sync.sh`). CachyOS stays the
default Limine entry; if NixOS fails to boot, nothing else is affected.
