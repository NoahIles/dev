# What the desktop relies on that the repo doesn't declare

Found by booting `.#vm` with a fresh disk (2026-10-27) and diffing against NixIsland.

## Fixed in 30dc2b8
- `_isVM` never reached HM: `extraSpecialArgs` is a plain attrs option, so `mkForce` in vm.nix lost to the shared `false`. Every VM dotfile (niri, noctalia, fish, …) was a dangling symlink into `~/nixos`. Now set per host.
- Later replaced: `_isVM` and the VM's read-only store-copied dotfiles are gone (fish couldn't write `fish_variables`). vm.nix now seeds `~/nixos` from the flake source on first boot, so the VM links live-lane dotfiles exactly like the host.
- VM SSH forward pointed at guest port 22; sshd listens on 2222 (`modules/ssh.nix`). Use `ssh -p 2223 noah@localhost`.
- VM wallpaper: the shared noctalia seed (modules/noctalia.nix) now rewrites its `~/Pictures` wallpaper paths to the repo's default, `/etc/backgrounds/default.jpeg`, so host and VM fresh installs get the same image.

## Undeclared state (only on the real machine)
| What | Where | Effect without it |
|---|---|---|
| Noctalia settings: bar layout, widgets, dock, lockscreen, idle, theme, UI scale 1.15, plugins config | `~/.local/state/noctalia/settings.toml` (332 lines) | Stock noctalia bar/theme |
| Noctalia plugins + community templates | `~/.local/state/noctalia/plugins`, `community-templates/` | Plugins missing |
| Wallpapers | `~/Pictures/UW_Wallpapers`, `~/Pictures/UHD_Wallpapers` | No wallpaper |
| TTS venv | `~/.claude/hooks/tts-venv` | Kokoro TTS hook breaks |
| peon-ping | `modules/fish.nix` aliases `peon` to `~/.claude/hooks/peon-ping/peon.sh` — doesn't exist on NixIsland either | `peon` function is dead |
| WirePlumber rule | `~/.config/wireplumber/wireplumber.conf.d/60-route-games-to-game.conf` | Games not routed to Game sink |
| Mailspring autostart | `~/.config/autostart/Mailspring.desktop` | No autostart |
| Flatpak apps | `services.flatpak.enable` but apps installed by hand | None installed |
| Greeter palette/wallpaper | noctalia "Sync Now" → greeter `sync.toml` | Stock greeter look |
| Rest of `~/.config` | shared @home with CachyOS (by design, see home.nix) | — |

## Breaks in VM (works on hardware)
- `gpu-screen-recorder` user unit crash-loops every 5s: hardcoded `-w DP-1`.
- `claude-shut-up` keybind (Ctrl+Esc) has no binary: agent-tts is NixIsland-only.
