# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Noah's personal NixOS config, forked from vimjoyer's flake-starter-config. The
root `flake.nix` is a **template registry only** — it has no `nixosConfigurations`
of its own. Each top-level folder (currently just `desktop/`) is a
self-contained flake with its own `flake.nix`/`flake.lock` and is the thing
actually built.

## Workflow

Work in a worktree, merge into `nixos` when done. Every commit on `nixos`
must evaluate cleanly (`nix eval .#nixosConfigurations.desktop...`). `vm`
is `sharedModules ++ [./vm.nix]` (see `desktop/flake.nix`) — identical
modules to `desktop` otherwise, so a `desktop` eval covers `vm` too,
*except* where behavior is conditioned on the `_isVM` HM arg (currently
just `modules/home/dotfiles.nix`) or on options `vm.nix` overrides with
`lib.mkForce` (`hardware.nvidia.modesetting.enable`,
`services.xserver.videoDrivers`, `hardware.bluetooth.enable`,
`boot.loader.systemd-boot.enable`, `fileSystems."/"`). Only re-check
`.vm...` when a change touches one of those, or `vm.nix` itself. Noah
handles pushing.

```bash
./rebuild.sh                          # format, rebuild, commit
./rebuild.sh "commit subject" "body"  # same, with a custom commit message
sudo nixos-rebuild switch --flake .#desktop   # what rebuild.sh wraps
alejandra -q .                        # format *.nix (rebuild.sh does this automatically)
```

`rebuild.sh` is the normal workflow, not `nixos-rebuild` directly: it formats
with alejandra, no-ops if no `*.nix` changed, rebuilds, then commits with a
generation line and the `nvd diff /run/current-system result` output appended
to the message body. The Limine bootloader module handles ESP sync (kernel
copy + signing) automatically on rebuild.

There is no test suite or linter beyond `alejandra` formatting and
`nixos-rebuild`'s own evaluation/build.

## Architecture

- **Dual-boot, shared `@home` btrfs subvolume with CachyOS.** NixOS lives in
  its own `@nixos` subvolume; `/home` is the *same* subvolume CachyOS uses.
  Historically this meant home-manager in `desktop/home.nix` managed
  **packages only** and never wrote dotfiles, since `~/.config` is canonical
  on the shared home. That's now being migrated piecemeal: HM has started
  managing individual dotfiles (via `programs.*` modules or `xdg.configFile`)
  where it makes sense — ghostty and herdr are the first ones. Most of
  `~/.config` (niri, noctalia, fish, etc.) is still loose/canonical on the
  shared home pending further migration; check `desktop/home.nix` for what's
  currently HM-managed before assuming a config file is safe to hand-edit.
- **NixOS owns Limine.** `boot.loader.limine.enable = true` with
  `secureBoot.enable = true` — NixOS manages the Limine binary, config, and
  signing via the native module. CachyOS and Windows are static entries in
  `extraEntries`. The old `limine-sync.sh` is no longer used.
- **Secure Boot**: Limine EFI binary is signed with `sbctl` (keys under
  `/var/lib/sbctl`, originally from the CachyOS install).
- niri (Wayland compositor) + noctalia (shell) is the desktop environment;
  greetd autologins straight into `niri-session`.
- `nixpkgs-unstable` is pulled in alongside the pinned `nixos-26.05` release
  channel for packages that need newer versions than stable ships (see the
  `television` comment in `configuration.nix` for the pattern:
  `pkgs-unstable = import inputs.nixpkgs-unstable { inherit (pkgs) system; }`).
- Flake inputs follow the main `nixpkgs` via `inputs.nixpkgs.follows` except
  `noctalia`, which follows `nixpkgs-unstable`.
- `docs/superpowers/specs/` holds design-decision specs (e.g. a since-moved
  VM trial profile, now on the `vm-flake` branch) — check there for
  historical context on profile/architecture decisions before re-deriving
  them.

## Conventions

- `// ponytail:` comments mark deliberate simplifications/deferred work —
  read them before "fixing" something that looks incomplete (e.g. the
  `initialPassword`, the RTX 4080 driver config placeholder for
  `nixos-generate-config` merge at install time).
- Format all `*.nix` with `alejandra` before committing.
