# nixos flake config

Personal NixOS config flake, forked from vimjoyer's flake-starter-config.
Each top-level folder is a self-contained config profile.

## Layout

- `flake.nix` — template registry (one template per profile folder)
- `default/` — **bare-metal desktop**: niri + noctalia, dual-boot with
  CachyOS on the same btrfs, `@home` shared. HM installs packages only and
  manages no files — `~/.config` on the shared home stays canonical.
- `vm/` — **QEMU trial VM**: same stack, but with a `dotfiles/` snapshot
  deployed on activation (the VM's home starts empty).

## Try it in a VM (from any machine with nix + flakes)

```bash
./vm/run-vm.sh
```

Autologs into a niri session as user `noah` (password `noah`).
`run-vm.sh` builds the VM then runs it with the **host** qemu — the nix-built
qemu can't load host GL drivers on non-NixOS hosts (`/run/opengl-driver`
missing), and niri refuses software rendering, so virgl needs host qemu.
Debug from outside: `ssh -p 2222 noah@localhost`. Reset: delete
`vm/nixos-vm.qcow2`.

VM dotfiles are **copied** (not symlinked) on activation because noctalia
rewrites `settings.json` and `niri/noctalia.kdl` at runtime. Re-sync from the
live system: `cp -r ~/.config/niri vm/dotfiles/` plus the four noctalia files
(settings.json, colors.json, plugins.json, user-templates.toml).

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
nixos-install --root /mnt/nixos --no-root-passwd --flake ./default#desktop
cp -a /var/lib/sbctl /mnt/nixos/var/lib/   # so NixOS can sign kernels too
# copy+sign kernel to ESP, write /+NixOS limine.conf entry
./default/limine-sync.sh /mnt/nixos
```

`limine-sync.sh` keeps the Limine entry pointing at `boot():/nixos/bzImage`
with blake2b hashes, cmdline `init=/nix/var/nix/profiles/system/init` — so
ordinary `nixos-rebuild switch` needs nothing, only **kernel version bumps**
need a re-run (from NixOS: `sudo ./limine-sync.sh`). CachyOS stays the
default Limine entry; if NixOS fails to boot, nothing else is affected.
