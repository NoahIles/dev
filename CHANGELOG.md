# Changelog

Unpushed work on `nixos` — 55 commits, `origin/nixos..nixos` (2026-08-27 → 2026-09-20).

## Added

- **Headless NixOS-WSL host** (`headless/`). Self-contained flake, attribute
  `NixWsl`, no GUI. Pulls `cli.nix`, `identity.nix` and the Claude module from
  `desktop/` via a source-only `path:../desktop` input so the two hosts can't
  drift. Registered as a template in the root `flake.nix`. See `headless/README.md`.
- **Claude Code config module** (`desktop/modules/home/claude.nix` +
  `desktop/configs/claude/`). `mkOutOfStoreSymlink`s settings, CLAUDE.md,
  statusline, skills, commands, output-styles and the wiki-sync hook into
  `~/.claude`, so Claude's own runtime writes land as git diffs. Rationale in
  `docs/adr/0002-claude-config-live-lane.md`.
- **Screen recording / clips.** `gpu-screen-recorder` replay buffer as a user
  unit (DP-1, 60s, RAM), F24 flushes it via `systemctl --user kill`, and
  `configs/niri/scripts/gsr-save-hook` files each clip under
  `~/Videos/clips/<window title>/` and notifies.
- **TTS speech modes.** `off` / `gist` / `conversational` replace the old
  `ENABLED` flag; playback runs as a transient `claude-tts-play` unit so a new
  clip supersedes the old one. New `claude-tts-prompt` (interrupt on submit +
  gist-line injection), `claude-shut-up` (bound to `Ctrl+Escape`),
  `claude-tts-config` and a browser config UI (`pkgs/kokoro-tts/ui.html`).
  Glossary in `CONTEXT.md`.
- **`arr-grab`** (fish): force-grab a specific TorrentDay release through
  Radarr/Sonarr by URL or id; accepts titles as well as Servarr ids, with
  accent folding and trailing-year fallback for matching.
- **`managarr`** CLI wired to Radarr/Sonarr (`configs/managarr/config.yml`),
  plus `efibootmgr`, `nix-output-monitor`, `nh`, `python3`, `libnotify`,
  `ffmpegthumbnailer`.
- Build timing and `nom --json` progress in `rebuild.sh`.

## Changed

- **Host renamed `nixos` → `NixIsland`**; the flake attribute follows
  (`nixosConfigurations.NixIsland`). `NH_OS_FLAKE` points at `desktop/`.
- **noctalia no longer follows our nixpkgs** — tracks its own `cachix` branch
  with the `noctalia.cachix.org` substituter, so it comes from the binary cache
  instead of compiling locally.
- Kernel moved to `linuxPackages_testing` (7.3 RCs) for the Superstrike
  receiver id.
- niri visuals: corner radius 20→14, global opacity 0.9→0.95, unfocused windows
  dim to 0.78, xray and blur noise/saturation off, Nautilus floats, per-app
  default column widths (Zed 0.75, terminals/Discord 0.33), floating Alacritty
  pinned to a fixed size.
- `pipewire-pulse` loads `module-device-manager` so pavucontrol device choices
  stick.
- `xdg.userDirs` enabled for Nautilus special-folder icons.
- Fish: arch-era aliases (`paru`, `pamcan`, taskwarrior, `q`) dropped; `update`
  is now `nh os switch --update --commit-lock-file`.
- `CLAUDE.md` trimmed of stale architecture notes, gained repo rules (no
  `git add -A`, don't pass messages through `just rebuild`, branch worktrees
  from local `nixos`).

## Fixed

- `reboot-windows` resolves the Windows EFI entry by name instead of a
  hardcoded `0001`.
- `rebuild.sh` restarts `polkit-soteria` after switch — the switch restarts
  polkitd and the agent's registration dies with it, leaving `pkexec` broken.
- TTS Stop hook waits for the transcript tail to be an assistant text block, so
  it no longer speaks the previous turn.
- TTS docs point at `/config`; `/output-style` was removed in v2.1.91.

## Removed

- `zt-toggle` — the noctalia ZeroTier plugin owns the bar toggle now.
- `scx_lavd` disabled: lavd 1.1.3 is ABI-skewed against kernel 7.2 and caused
  21s RCU stalls on a ~30s loop. Re-enable when scx matches the kernel.
- `claude-code` from nixpkgs — the native installer's binary is used instead so
  it keeps auto-updating.
