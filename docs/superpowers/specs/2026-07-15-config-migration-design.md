# Config migration: shared ~/.config → nix-managed

**Date:** 2026-07-15
**Status:** approved design, pending implementation plan

## Goal

Retire the "shared loose `~/.config`" bandaid between CachyOS and NixOS.
Hand-written configs move into the flake repo (`desktop/configs/`) and are
deployed by home-manager as symlinks into `~/.config`. `~/.config` itself
becomes a dedicated btrfs subvolume so the remaining unmanaged app state is
quarantined and the nix deployment can be tested from a clean state.
The repo is assumed to eventually go public.

## Architecture

### 1. `@config` btrfs subvolume

- New **top-level** subvolume `@config`, sibling of `@home`/`@nixos`.
- Current `~/.config` contents move into it (preserves everything for
  CachyOS; nothing is deleted).
- NixOS mounts it at `/home/noah/.config` via `fileSystems` (add `nofail`
  so an unmounted boot still works). CachyOS gets one fstab line.
- The move happens from a TTY with the graphical session stopped (nothing
  writing to `~/.config`). Privileged steps use `pkexec`/`sudo`.
- **Clean-state test:** `pkexec umount ~/.config`, rerun HM activation
  (`nixos-rebuild switch` or restart the HM service) — the nix-managed
  setup materializes into the empty directory.

### 2. `desktop/configs/` — canonical config home in the repo

Hand-written configs are **moved** (not copied) out of `~/.config` into
`desktop/configs/<program>/`, one program per commit.

### 3. Two deployment lanes in `home.nix`

A single `let` binding keeps the repo path in one place:

```nix
configsDir = "${config.home.homeDirectory}/nixos/desktop/configs";
```

**Live lane** — whole-dir out-of-store symlink
(`xdg.configFile."X".source = config.lib.file.mkOutOfStoreSymlink
"${configsDir}/X"`). Hand-edits hot-reload instantly; GUI/runtime writes
land in the repo as git diffs. Members:

| Program | Notes |
|---|---|
| niri | kdl files + scripts, hot-reload workflow preserved |
| noctalia | GUI writes settings.json — tracked (it *is* the config); gitignore generated `colors.json` |
| fish | runtime writes (fisher, fish_variables) need a writable dir; **cleanup during migration** — drop CachyOS/Hypr leftovers (`auto-Hypr.fish`, `auto-kde.fish`, `cachyos-fish-config.fish`, `*.bak`); gitignore `fish_variables` + fisher-generated files |
| zed | GUI-written settings.json; small now, grows over time |

**Stable lane** — per-file pure HM symlinks (store-backed, rebuild to
change). **Rule: for any dir noctalia's theming writes into, manage
individual files only, never the whole dir** — generated theme files stay
loose beside the symlink. Members:

| Program | Managed file(s) |
|---|---|
| fuzzel | `fuzzel.ini` (themes/ stays loose) |
| swaylock | `config` |
| mpv | `mpv.conf` |
| television | `config.toml`, `cable/` |

**Skipped** (machine-owned, empty, or never hand-edited): tmux, starship,
yazi, zathura, micro, btop (`btop.conf` is self-rewritten), lazygit
(empty). They stay loose in `@config`.

### 4. Secret scanning — pre-push hook

- `gitleaks` (nixpkgs) — no custom scanner.
- Tracked hook at `scripts/pre-push` running gitleaks over the outgoing
  range; enabled via `git config core.hooksPath scripts`.
- Fires only on push, per requirement. `fish_variables` and other
  secret-prone runtime files are gitignored regardless.

## Migration procedure (per program)

1. Move config from `~/.config/X` to `desktop/configs/X`.
2. Wire into `home.nix` (live or stable lane).
3. `./rebuild.sh` — HM places the symlink where the loose file was.
4. Verify the program works (niri: `niri validate` + hot-reload check).
5. Commit. One program per commit → every step revertible.

## Phases

1. **Pre-push gitleaks hook** (trivial, protects everything after).
2. **`@config` subvolume** — create, move state, mount on both OSes (TTY
   session required).
3. **Per-program migration** — live lane first (niri, noctalia, fish
   cleanup, zed), then stable lane.

## Failure modes

- Repo not at `~/nixos` → live-lane symlinks dangle; programs fall back to
  defaults, nothing corrupts. Path is defined once via
  `home.homeDirectory`.
- `@config` unmounted at boot (`nofail`) → empty `~/.config`; HM rebuild
  recreates all managed entries (this is the clean-state test, not a
  failure).
- CachyOS boots before its fstab gains the `@config` line → sees an empty
  `~/.config` dir inside `@home`. Add the fstab line in the same session
  as the subvolume move.

## Out of scope

- wrapper-modules (revisit only on concrete need).
- Migrating app *state* (browsers, launchers) — stays in `@config`.
- Retiring the shared `@home` itself.
