# nixos flake config

Personal NixOS config flake, forked from vimjoyer's flake-starter-config.
Each top-level folder is a self-contained config; `default/` is the main one
(niri + noctalia). Add sibling folders to try alternate configs.

## Layout

- `flake.nix` — template registry (one template per config folder)
- `default/` — niri + noctalia config: flake.nix, configuration.nix, home.nix, dotfiles/

## Try it in a VM (from any machine with nix + flakes)

```bash
cd default
nixos-rebuild build-vm --flake .#vm
./result/bin/run-nixos-vm-vm
```

Autologs into a niri session as user `noah` (password `noah`).

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
