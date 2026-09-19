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
must evaluate cleanly (`nix eval .#nixosConfigurations.NixIsland...`, run from `desktop/`). `vm`
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
just rebuild                          # format, rebuild, commit
just rebuild "commit subject" "body"  # same, with a custom commit message
sudo nixos-rebuild switch --flake .#NixIsland   # what rebuild.sh wraps
alejandra -q .                        # format *.nix (rebuild.sh does this automatically)
```

`rebuild.sh` is the normal workflow, not `nixos-rebuild` directly: it formats
with alejandra, no-ops if no `*.nix` changed, rebuilds, then commits with a
generation line and the `nvd diff /run/current-system result` output appended
to the message body. The Limine bootloader module handles ESP sync (kernel
copy + signing) automatically on rebuild.

There is no test suite or linter beyond `alejandra` formatting and
`nixos-rebuild`'s own evaluation/build.

### Repo rules (promoted from auto memory, 2026-09-19)

- **Never `git add -A` in this repo's automation.** Only already-tracked
  modifications may be staged automatically (`git commit -a`, `git add -u`).
  Noah adds new files by hand on purpose: flakes ignore untracked files, so a
  new `.nix` file failing the build is the intended signal, not something
  tooling should paper over.
- **Don't pass a commit message through `just rebuild`.** The recipe
  interpolates `{{ args }}` unquoted, so a multi-word subject or body is
  word-split, and the failure only surfaces *after* the commit exists. Call the
  script directly: `cd ~/nixos/desktop && ./rebuild.sh "subject" "body"`.
- **A new worktree may start from a stale tree.** `origin/nixos` lags local
  `nixos` by a lot, since Noah pushes rarely, and `EnterWorktree` branches from
  the remote by default. Branch from local `nixos`, and re-run the eval on the
  merged tree before calling anything verified:
  `nix build --no-link --dry-run ./desktop#nixosConfigurations.NixIsland.config.system.build.toplevel`.

## Architecture

- **NixOS owns Limine.** `boot.loader.limine.enable = true` with
  `secureBoot.enable = true` — NixOS manages the Limine binary, config, and
  signing via the native module. CachyOS and Windows are static entries in
  `extraEntries`. The old `limine-sync.sh` is no longer used.
- **Secure Boot**: Limine EFI binary is signed with `sbctl` (keys under
  `/var/lib/sbctl`, originally from the CachyOS install).
- niri (Wayland compositor) + noctalia (shell) is the desktop environment;
  greetd autologins straight into `niri-session`.

## Conventions

- `// ponytail:` comments mark deliberate simplifications/deferred work —
  read them before "fixing" something that looks incomplete (e.g. the
  `initialPassword`, the RTX 4080 driver config placeholder for
  `nixos-generate-config` merge at install time).
- Format all `*.nix` with `alejandra` before committing.
