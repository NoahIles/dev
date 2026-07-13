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

`default/configuration.nix` already has the real UUIDs for nvme0n1p1 (btrfs),
the shared ESP, and the games drive. At install time:

1. Boot the NixOS ISO, then:
   `mount /dev/nvme0n1p1 /mnt && btrfs subvolume create /mnt/@nixos && umount /mnt`
2. Mount `@nixos` at /mnt, `@home` at /mnt/home, ESP at /mnt/boot.
3. `nixos-generate-config --root /mnt` and merge anything missing
   (initrd modules, microcode) into `default/configuration.nix`.
4. `nixos-install --flake /path/to/repo/default#desktop`
5. `passwd noah` on first boot.

**Secure Boot caveat:** the ESP is shared with Windows + CachyOS/Limine and
SB is enabled with user keys. systemd-boot/NixOS kernels are unsigned —
either sign them, add a Limine entry, or disable SB for the trial period.
