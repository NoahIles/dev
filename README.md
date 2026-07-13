# nixos flake config

Personal NixOS config flake, forked from vimjoyer's flake-starter-config.
Each top-level folder is a self-contained config; `default/` is the main one
(niri + noctalia). Add sibling folders to try alternate configs.

## Layout

- `flake.nix` — template registry (one template per config folder)
- `default/` — niri + noctalia config: flake.nix, configuration.nix, home.nix, dotfiles/

## Try it in a VM (from any machine with nix + flakes)

```bash
./default/run-vm.sh
```

Autologs into a niri session as user `noah` (password `noah`).
`run-vm.sh` builds the VM then runs it with the **host** qemu — the nix-built
qemu can't load host GL drivers on non-NixOS hosts (`/run/opengl-driver`
missing), and niri refuses software rendering, so virgl needs host qemu.
Debug from outside: `ssh -p 2222 noah@localhost`. Reset: delete
`default/nixos-vm.qcow2`.

## Install on real hardware

```bash
cd /etc/nixos
sudo nix flake init --template /path/to/this/repo   # copies default/
sudo nixos-generate-config   # then replace the VM stubs in configuration.nix
sudo nixos-rebuild switch --flake /etc/nixos#vm
```

## Notes

- Dotfiles are **copied** (not symlinked) on activation because noctalia
  rewrites `settings.json` and `niri/noctalia.kdl` at runtime. Rebuilds
  overwrite runtime changes — durable edits go in `default/dotfiles/`.
- Sync dotfiles from the live system: `cp -r ~/.config/niri default/dotfiles/`
  plus the four noctalia files (settings.json, colors.json, plugins.json,
  user-templates.toml).
