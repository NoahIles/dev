# What the desktop relies on that the repo doesn't declare

Found by booting `.#vm` with a fresh disk (2026-10-27) and diffing against NixIsland.

## Fixed in 30dc2b8
- `_isVM` never reached HM: `extraSpecialArgs` is a plain attrs option, so `mkForce` in vm.nix lost to the shared `false`. Every VM dotfile (niri, noctalia, fish, …) was a dangling symlink into `~/nixos`. Now set per host.
- VM SSH forward pointed at guest port 22; sshd listens on 2222 (`modules/ssh.nix`). Use `ssh -p 2223 noah@localhost`.
- VM wallpaper: vm.nix seeds `~/.local/state/noctalia/settings.toml` once with nixos-artwork `nineish-dark-gray`.

## Undeclared state (only on the real machine)
| What | Where | Effect without it |
|---|---|---|
| Noctalia settings: bar layout, widgets, dock, lockscreen, idle, theme, UI scale 1.15, plugins config | `~/.local/state/noctalia/settings.toml` (332 lines) | Stock noctalia bar/theme |
| Noctalia plugins + community templates | `~/.local/state/noctalia/plugins`, `community-templates/` | Plugins missing |
| Wallpapers | `~/Pictures/UW_Wallpapers`, `~/Pictures/UHD_Wallpapers` | No wallpaper |
| Claude Code binary | native installer, not nix | `~/.claude/*` links dangle in VM; `claude` missing |
| TTS venv | `~/.claude/hooks/tts-venv` | Kokoro TTS hook breaks |
| peon-ping | `config.fish` calls `~/.claude/hooks/peon-ping/peon.sh` — doesn't exist on NixIsland either | `peon` function is dead |
| Fisher plugins | `configs/fish/fish_plugins` lists 3; installed by fisher at runtime | Not installed on fresh box |
| WirePlumber rule | `~/.config/wireplumber/wireplumber.conf.d/60-route-games-to-game.conf` | Games not routed to Game sink |
| Mailspring autostart | `~/.config/autostart/Mailspring.desktop` | No autostart |
| Flatpak apps | `services.flatpak.enable` but apps installed by hand | None installed |
| Greeter palette/wallpaper | noctalia "Sync Now" → greeter `sync.toml` | Stock greeter look |
| Rest of `~/.config` | shared @home with CachyOS (by design, see home.nix) | — |

## Breaks in VM (works on hardware)
- `gpu-screen-recorder` user unit crash-loops every 5s: hardcoded `-w DP-1`.
- `fish_variables` is in the repo and the store lane makes it read-only, so fish prints "Unable to create temporary file" on every shell in the VM. It's fish runtime state; probably shouldn't be tracked.
- `claude-shut-up` keybind (Ctrl+Esc) has no binary: kokoro-tts is NixIsland-only.
