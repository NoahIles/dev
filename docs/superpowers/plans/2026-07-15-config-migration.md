# Config Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate hand-written configs off the shared `~/.config` into `desktop/configs/` (deployed by home-manager), quarantine the rest in a new `@config` btrfs subvolume, and gate pushes with gitleaks.

**Architecture:** Two HM lanes — live (whole-dir `mkOutOfStoreSymlink` into the repo checkout: niri, noctalia, fish, zed) and stable (per-file store symlinks: fuzzel, swaylock, mpv, television). `~/.config` becomes a top-level `@config` subvolume mounted by both OSes. Spec: `docs/superpowers/specs/2026-07-15-config-migration-design.md`.

**Tech Stack:** NixOS 26.05 flake at `~/nixos/desktop`, home-manager (NixOS module), btrfs, gitleaks.

## Global Constraints

- Repo root: `/home/noah/nixos`; flake + `rebuild.sh` live in `desktop/`, run from there.
- `./rebuild.sh "subject"` formats, rebuilds, and commits **tracked** changes (`git commit -av`). `git add` any new files BEFORE running it so they land in the same commit.
- Repo assumed to eventually go public — no secrets may be committed.
- btrfs device: `/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702` (top-level subvols `@home`, `@nixos`, CachyOS `@`).
- Verified via `alejandra` + rebuild success + per-program checks; there is no test suite.
- One program per commit; every task independently revertible.

### Spec deviations (decided during planning)

- Fisher-generated fish files are **tracked**, not gitignored — they can't be distinguished by glob and are public code anyway. Only `fish_variables` and `*.bak` are ignored.
- `television/cable/` stays loose (machine-managed by `tv update-channels`); only `config.toml` migrates.

---

### Task 1: gitleaks pre-push hook

**Files:**
- Modify: `desktop/home.nix` (add `gitleaks` to `home.packages`, dev section)
- Create: `scripts/pre-push` (repo root, executable)

**Interfaces:**
- Produces: `git push` on this repo runs a full-history gitleaks scan and blocks on findings.

- [ ] **Step 1: Add gitleaks to home.packages**

In `desktop/home.nix`, in the `# dev` section after `tealdeer`:

```nix
    gitleaks # secret scanner, run by scripts/pre-push
```

- [ ] **Step 2: Rebuild**

Run: `cd /home/noah/nixos/desktop && ./rebuild.sh "home: add gitleaks"`
Expected: rebuild succeeds, commit created. Verify: `command -v gitleaks` prints a store path.

- [ ] **Step 3: Create the hook**

Create `/home/noah/nixos/scripts/pre-push`:

```bash
#!/usr/bin/env bash
# Block pushes if gitleaks finds secrets anywhere in history.
# Full-history scan on purpose: this repo is headed for a public remote.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
exec gitleaks git --redact
```

Run: `chmod +x /home/noah/nixos/scripts/pre-push`

- [ ] **Step 4: Enable and verify**

```bash
cd /home/noah/nixos
git config core.hooksPath scripts
./scripts/pre-push
```

Expected: gitleaks output ending `no leaks found`, exit 0. If it flags historical leaks, STOP and surface them to Noah before any remote is added.

- [ ] **Step 5: Verify detection works**

```bash
d=$(mktemp -d) && echo 'aws_key = "AKIAIOSFODNN7EXAMPLE"' > "$d/leaktest"; gitleaks dir "$d"; echo "exit: $?"; rm -r "$d"
```

Expected: `exit: 1` (the canary AWS key is detected).

- [ ] **Step 6: Commit**

```bash
cd /home/noah/nixos
git add scripts/pre-push
git commit -m "add gitleaks pre-push hook (core.hooksPath scripts)"
```

Note: `core.hooksPath` is local git config — after a fresh clone it must be re-run once; the hook file itself is tracked.

---

### Task 2: `@config` subvolume

**Files:**
- Create: `desktop/scripts/migrate-config-subvol.sh` (executable)
- Modify: `desktop/configuration.nix` (add `fileSystems."/home/noah/.config"`)
- Modify (manual, other OS): CachyOS `/etc/fstab`

**Interfaces:**
- Produces: `~/.config` is a mounted `@config` subvolume on both OSes; unmounting it yields an empty dir for clean-state testing.

- [ ] **Step 1: Write the migration script**

Create `desktop/scripts/migrate-config-subvol.sh`:

```bash
#!/usr/bin/env bash
# One-shot: move ~/.config into a new top-level @config btrfs subvolume.
# Run as root from a TTY with the graphical session logged OUT.
set -euo pipefail
DEV=/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702
CFG=/home/noah/.config
MNT=$(mktemp -d)

[ "$(id -u)" = 0 ] || { echo "run as root (sudo/pkexec)"; exit 1; }
if fuser -m "$CFG" >/dev/null 2>&1; then
    echo "processes still using $CFG — log out of the session first:"
    fuser -vm "$CFG" || true
    exit 1
fi

mount -o subvol=/ "$DEV" "$MNT"
trap 'umount "$MNT" && rmdir "$MNT"' EXIT
[ -e "$MNT/@config" ] && { echo "@config already exists, aborting"; exit 1; }

btrfs subvolume create "$MNT/@config"
echo "copying (reflink, fast)..."
cp -a --reflink=always "$CFG/." "$MNT/@config/"
chown noah:users "$MNT/@config"

src=$(find "$CFG" | wc -l); dst=$(find "$MNT/@config" | wc -l)
[ "$src" = "$dst" ] || { echo "file count mismatch ($src vs $dst), aborting before delete"; exit 1; }

find "$CFG" -mindepth 1 -delete
mount -o subvol=@config,noatime,compress=zstd:3,discard=async,commit=120 "$DEV" "$CFG"
echo "OK: @config created and mounted at $CFG."
echo "Next: rebuild with the fileSystems entry, then add the CachyOS fstab line."
```

Run: `chmod +x /home/noah/nixos/desktop/scripts/migrate-config-subvol.sh`

- [ ] **Step 2: Commit the script (before the TTY session, so it's on disk and reviewable)**

```bash
cd /home/noah/nixos
git add desktop/scripts/migrate-config-subvol.sh
git commit -m "add @config subvolume migration script"
```

- [ ] **Step 3: USER ACTION — run it from a TTY**

Noah: switch to a TTY (Ctrl+Alt+F3), log in, stop the graphical session (log out of niri first), then:

```bash
sudo ~/nixos/desktop/scripts/migrate-config-subvol.sh
```

Expected: `OK: @config created and mounted`. If `fuser` blocks it, log the session out fully and retry.

- [ ] **Step 4: Add the NixOS mount**

In `desktop/configuration.nix`, next to the other `fileSystems`/hardware imports (any top-level position works):

```nix
  # ~/.config is its own subvolume — unmanaged app state quarantined from
  # @home; unmount + rebuild = clean-state test of the HM-managed setup.
  fileSystems."/home/noah/.config" = {
    device = "/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702";
    fsType = "btrfs";
    options = ["subvol=@config" "noatime" "compress=zstd:3" "discard=async" "commit=120" "nofail"];
  };
```

- [ ] **Step 5: Rebuild and verify**

Run: `cd /home/noah/nixos/desktop && ./rebuild.sh "mount ~/.config from @config subvolume"`
Expected: success. Verify: `findmnt /home/noah/.config` shows `subvol=/@config`.

- [ ] **Step 6: USER ACTION — CachyOS fstab**

Add to CachyOS `/etc/fstab` (from a CachyOS boot, or by mounting its root subvol from NixOS):

```
UUID=288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702 /home/noah/.config btrfs subvol=/@config,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,commit=120,nofail 0 0
```

Verify on next CachyOS boot: `findmnt /home/noah/.config`.

---

### Task 3: live-lane plumbing + niri

**Files:**
- Modify: `desktop/home.nix` (add `config` arg, `configsDir`/`live` helpers, niri entry)
- Create: `desktop/configs/niri/` (moved from `~/.config/niri`)
- Create: `.gitignore` (repo root)

**Interfaces:**
- Produces: `live = name: { source = config.lib.file.mkOutOfStoreSymlink "${configsDir}/${name}"; }` — Tasks 4–6 reuse it as `xdg.configFile."X" = live "X";`.

- [ ] **Step 1: Add plumbing to home.nix**

Change the header and `let` of `desktop/home.nix`:

```nix
{
  config,
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
  # live-lane dotfiles: symlink to the repo checkout (not the store) so
  # hand-edits hot-reload and GUI writes land as git diffs. Dangles if the
  # repo isn't at ~/nixos — programs then fall back to defaults.
  configsDir = "${config.home.homeDirectory}/nixos/desktop/configs";
  live = name: {source = config.lib.file.mkOutOfStoreSymlink "${configsDir}/${name}";};
in {
```

- [ ] **Step 2: Create repo .gitignore**

Create `/home/noah/nixos/.gitignore`:

```gitignore
# machine-written / secret-prone runtime files inside migrated configs
desktop/configs/fish/fish_variables
desktop/configs/noctalia/colors.json
desktop/configs/**/*.bak
```

- [ ] **Step 3: Move niri into the repo**

```bash
mkdir -p /home/noah/nixos/desktop/configs
mv /home/noah/.config/niri /home/noah/nixos/desktop/configs/niri
```

- [ ] **Step 4: Wire it**

In `desktop/home.nix` body (after the `xdg.configFile."herdr/config.toml"` block):

```nix
  xdg.configFile."niri" = live "niri";
```

- [ ] **Step 5: Rebuild**

```bash
cd /home/noah/nixos/desktop
git add -A ../.gitignore configs/niri
./rebuild.sh "migrate niri config into repo (live lane)"
```

Expected: success.

- [ ] **Step 6: Verify**

```bash
readlink /home/noah/.config/niri   # → /home/noah/nixos/desktop/configs/niri (via HM indirection is fine as long as it resolves)
niri validate                       # config parses
touch /home/noah/nixos/desktop/configs/niri/config.kdl && niri msg version >/dev/null && echo hot-path-ok
```

Expected: symlink resolves to the repo dir, `niri validate` passes. Confirm a trivial edit hot-reloads (change a border color, watch it apply, revert).

---

### Task 4: noctalia

**Files:**
- Create: `desktop/configs/noctalia/` (moved from `~/.config/noctalia`)
- Modify: `desktop/home.nix` (one line)

**Interfaces:**
- Consumes: `live` helper from Task 3.

- [ ] **Step 1: Move and wire**

```bash
mv /home/noah/.config/noctalia /home/noah/nixos/desktop/configs/noctalia
```

In `desktop/home.nix`, after the niri line:

```nix
  xdg.configFile."noctalia" = live "noctalia";
```

- [ ] **Step 2: Rebuild**

```bash
cd /home/noah/nixos/desktop
git add configs/noctalia
./rebuild.sh "migrate noctalia config into repo (live lane)"
```

Expected: success; `colors.json` NOT staged (gitignored — check `git status`).

- [ ] **Step 3: Verify**

Restart noctalia (or reload via its IPC), toggle any setting in the GUI, then:

```bash
git -C /home/noah/nixos diff --stat -- desktop/configs/noctalia/settings.json
```

Expected: the GUI toggle shows up as a diff → writes go through the symlink into the repo. Revert the toggle, commit if a diff remains.

---

### Task 5: fish (with cleanup)

**Files:**
- Create: `desktop/configs/fish/` (moved from `~/.config/fish`, minus deletions)
- Modify: `desktop/home.nix` (one line)

**Interfaces:**
- Consumes: `live` helper from Task 3.

- [ ] **Step 1: Cleanup — delete CachyOS/Hypr leftovers and .bak files**

```bash
cd /home/noah/.config/fish
rm auto-Hypr.fish auto-kde.fish conf.d/*.bak
rm -f user_scripts/cachyos-fish-config.fish
```

Then open `config.fish` and remove any lines sourcing the deleted files (search: `grep -n 'auto-Hypr\|auto-kde\|cachyos' config.fish user_scripts/*.fish`).

- [ ] **Step 2: Secret sweep before it enters the repo**

```bash
gitleaks dir /home/noah/.config/fish
grep -rn 'sk-\|api[_-]key\|token' /home/noah/.config/fish --include='*.fish' -i | grep -vi 'bind\|key_bindings' || echo clean
```

Expected: no findings (fish_variables is gitignored anyway; fish_ai's key lives in `~/.config/fish-ai.ini`, which is NOT migrated). If findings: strip them or gitignore that file before proceeding.

- [ ] **Step 3: Move and wire**

```bash
mv /home/noah/.config/fish /home/noah/nixos/desktop/configs/fish
```

In `desktop/home.nix`, after the noctalia line:

```nix
  xdg.configFile."fish" = live "fish";
```

- [ ] **Step 4: Rebuild and verify**

```bash
cd /home/noah/nixos/desktop
git add configs/fish
./rebuild.sh "migrate fish config into repo (live lane, CachyOS leftovers removed)"
fish -c 'echo shell-ok'
fish -c 'set -U __migration_probe 1; set -eU __migration_probe; echo variables-writable'
```

Expected: both print; `fish_variables` writable through the symlink and absent from `git status`.

---

### Task 6: zed

**Files:**
- Create: `desktop/configs/zed/` (moved from `~/.config/zed`)
- Modify: `desktop/home.nix` (one line)

**Interfaces:**
- Consumes: `live` helper from Task 3.

- [ ] **Step 1: Move and wire**

```bash
mv /home/noah/.config/zed /home/noah/nixos/desktop/configs/zed
```

In `desktop/home.nix`, after the fish line:

```nix
  xdg.configFile."zed" = live "zed";
```

- [ ] **Step 2: Rebuild and verify**

```bash
cd /home/noah/nixos/desktop
git add configs/zed
./rebuild.sh "migrate zed config into repo (live lane)"
```

Then launch `zeditor`, change any setting in its settings UI, confirm `git -C /home/noah/nixos diff -- desktop/configs/zed` shows it, revert.

Note: zed's generated `themes/noctalia.json` gets tracked; harmless. If theme churn annoys later, add `desktop/configs/zed/themes/` to `.gitignore`.

---

### Task 7: stable lane (fuzzel, swaylock, mpv, television)

**Files:**
- Create: `desktop/configs/{fuzzel/fuzzel.ini,swaylock/config,mpv/mpv.conf,television/config.toml}` (moved)
- Modify: `desktop/home.nix`

**Interfaces:**
- Consumes: nothing from live lane — these are plain store-backed `xdg.configFile` entries. Rule from spec: per-FILE only; theme dirs stay loose.

- [ ] **Step 1: Move the hand-written files (only these files — themes/cable stay put)**

```bash
cd /home/noah/nixos/desktop/configs
mkdir -p fuzzel swaylock mpv television
mv /home/noah/.config/fuzzel/fuzzel.ini      fuzzel/fuzzel.ini
mv /home/noah/.config/swaylock/config        swaylock/config
mv /home/noah/.config/mpv/mpv.conf           mpv/mpv.conf
mv /home/noah/.config/television/config.toml television/config.toml
```

- [ ] **Step 2: Wire (store-backed — no `live`)**

In `desktop/home.nix`, after the zed line:

```nix
  # stable lane: store-backed, rebuild to change. Per-file on purpose —
  # noctalia's theming writes generated files beside these; never manage
  # the whole dir.
  xdg.configFile."fuzzel/fuzzel.ini".source = ./configs/fuzzel/fuzzel.ini;
  xdg.configFile."swaylock/config".source = ./configs/swaylock/config;
  xdg.configFile."mpv/mpv.conf".source = ./configs/mpv/mpv.conf;
  xdg.configFile."television/config.toml".source = ./configs/television/config.toml;
```

- [ ] **Step 3: Rebuild**

```bash
cd /home/noah/nixos/desktop
git add configs/fuzzel configs/swaylock configs/mpv configs/television
./rebuild.sh "migrate stable-lane configs (fuzzel, swaylock, mpv, television)"
```

Expected: success. (Flake eval requires these files to be git-added — done above.)

- [ ] **Step 4: Verify**

```bash
ls -la ~/.config/fuzzel/          # fuzzel.ini → store symlink; fuzzel_theme.ini + themes/ still loose
fuzzel --check-config 2>/dev/null || fuzzel --version
tv --version && ls ~/.config/television/cable | head -3
mpv --no-config --version >/dev/null && echo mpv-ok
```

Expected: fuzzel launches from its niri keybind with your prompt/font; television still lists channels; swaylock verified next actual lock.

---

### Task 8: clean-state test (the whole point)

**Files:** none — verification only.

- [ ] **Step 1: Unmount and rebuild**

```bash
pkexec umount /home/noah/.config
ls ~/.config                       # empty (or near-empty)
# plain switch re-runs HM activation; rebuild.sh would balk at the clean tree
cd /home/noah/nixos/desktop && sudo nixos-rebuild switch --flake .#desktop
ls -la ~/.config                   # niri, noctalia, fish, zed, fuzzel/, swaylock/, mpv/, television/ materialized as symlinks
niri validate && fish -c 'echo ok'
```

Expected: the nix-managed setup materializes into the empty dir; managed programs work. Unmanaged apps (browsers etc.) are amnesiac until remount — expected.

- [ ] **Step 2: Remount and confirm**

```bash
pkexec mount /home/noah/.config    # fstab/fileSystems entry
findmnt /home/noah/.config         # subvol=/@config again
```

Note: while `@config` was unmounted, HM wrote its symlinks into the *underlying* dir on `@home`. Once remounted that residue is shadowed and invisible — leave it.

- [ ] **Step 3: Update spec status**

Change the spec's `**Status:**` line to `implemented 2026-07-15` and commit:

```bash
cd /home/noah/nixos
git add docs/superpowers/specs/2026-07-15-config-migration-design.md
git commit -m "spec: mark config migration implemented"
```
