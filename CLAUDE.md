# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Noah's personal NixOS config, forked from vimjoyer's flake-starter-config. The
root `flake.nix` is a **template registry only** — it has no `nixosConfigurations`
of its own. Each top-level folder (currently just `desktop/`) is a
self-contained flake with its own `flake.nix`/`flake.lock` and is the thing
actually built.

## Workflow

Work in a worktree, merge into `nixos` when done. Background sessions'
worktree guard blocks git outside the worktree, so `ExitWorktree` (keep)
before merging into `nixos` or committing the wiki. Every commit on `nixos`
must pass `just check` (alejandra `--check` plus a dry-run eval of
`NixIsland`). Use the recipe rather than rebuilding the command by hand; run
`just` for the full menu. `vm`
is `sharedModules ++ [./vm.nix]` (see `desktop/flake.nix`) — identical
modules to `desktop` otherwise, so a `desktop` eval covers `vm` too,
*except* where `vm.nix` adds HM activation steps (seeding `~/nixos` on
first boot) or overrides options with
`lib.mkForce` (`hardware.nvidia.modesetting.enable`,
`services.xserver.videoDrivers`, `hardware.bluetooth.enable`,
`boot.loader.systemd-boot.enable`, `fileSystems."/"`). Only re-check
`.vm...` when a change touches one of those, or `vm.nix` itself. Noah
handles pushing.

```bash
cd ~/nixos/desktop && ./rebuild.sh                     # format, commit, build, switch, record gen
cd ~/nixos/desktop && ./rebuild.sh "subject" "body"    # same, with a custom work-commit message
nixos-rebuild build --flake .#NixIsland                # build only, no root needed
alejandra -q .                                         # format *.nix (rebuild.sh does this)
```

**Run `rebuild.sh` yourself when a rebuild or switch is asked for, and
also unprompted to validate a fix live** (Noah, 2026-11-05: validate before
handing back). Rebuilding without asking is fine unless it would interrupt
him, e.g. he said he's mid-task, or the switch would restart something he's
using.
`sudo nixos-rebuild` is NOPASSWD (`desktop/modules/identity.nix`), so the
script's sudo works from an agent shell. Never hand-roll the build + switch
(e.g. `pkexec nixos-rebuild switch`): that skips the `gen-N` tag,
and the pkexec prompt can't be answered remotely.

What `rebuild.sh` does (see `docs/adr/0003-gen-tags.md`): format with
alejandra, then `git commit -a` every tracked change as the work commit
(`wip: <timestamp>` unless a subject is given), build, print `nvd diff`,
`sudo nixos-rebuild switch --store-path`, then tag the built commit `gen-N`
(annotated; message holds the shortlog and nvd diff, `just gens` shows
them). It also runs on a clean tree if HEAD differs from the newest `gen-*`
tag. A failed build soft-resets the work commit. The Limine module handles
ESP sync (kernel copy + signing) on switch. Gens up to 202 are also empty
`rebuild: gen N` commits in history; leave them.

**HEAD moves under you:** Noah's own `rebuild.sh` runs may add a `wip:`
commit on top of your work, so check `git log -1` is yours before any
`git commit --amend`, or just make a new commit.

**Check `git status` before running it.** Because it sweeps every tracked
change, stop and ask if the repo is mid-rebase/merge or has tracked edits
unrelated to the task. Live-lane configs drift on their own: e.g.
`niri-zen-toggle` rewrites `desktop/configs/niri/niri.kdl` (zen mode,
the `game_mode.kdl` include). That drift is expected: don't ask about it
or commit it; keep it out of the rebuild with
`git update-index --skip-worktree` and undo that afterwards.

There is no test suite or linter beyond `alejandra` formatting and
`nixos-rebuild`'s own evaluation/build; `just check` runs both cheap halves.
One exception: `desktop/pkgs/agent-tts-cli` (the Rust TTS hooks) runs its unit
tests and a strict clippy in its package build, so a failure there fails the
rebuild. `cargo` is not on PATH: `nix shell nixpkgs#cargo nixpkgs#rustc
nixpkgs#clippy nixpkgs#gcc -c cargo test` from that directory.

### Repo rules (promoted from auto memory, 2026-09-19)

- **Never `git add -A` in this repo's automation.** Only already-tracked
  modifications may be staged automatically (`git commit -a`, `git add -u`).
  Noah adds new files by hand on purpose: flakes ignore untracked files, so a
  new `.nix` file failing the build is the intended signal, not something
  tooling should paper over.
- **`rebuild.sh` from a worktree is a full system switch:** the next
  rebuild from `nixos` drops branch-only features (claude-box, gen
  175→176). To trial a branch, merge `nixos` into it first. Before calling
  a branch tool live, check the gen's "Removed packages" and `~/.local/bin`
  side-installs.
- **A new worktree may start from a stale tree.** `origin/nixos` lags local
  `nixos` by a lot, since Noah pushes rarely, and `EnterWorktree` branches from
  the remote by default. Branch from local `nixos`, and re-run the eval on the
  merged tree (`just check`) before calling anything verified.

## Architecture

- **NixOS owns Limine.** `boot.loader.limine.enable = true` with
  `secureBoot.enable = true` — NixOS manages the Limine binary, config, and
  signing via the native module. CachyOS and Windows are static entries in
  `extraEntries`. The old `limine-sync.sh` is no longer used.
- **Secure Boot**: Limine EFI binary is signed with `sbctl` (keys under
  `/var/lib/sbctl`, originally from the CachyOS install).
- Desktop: noctalia (shell) on a choice of compositors, niri
  (`modules/niri.nix`) or umbriel (`modules/umbriel.nix`), picked at login by
  `noctalia-greeter` (`modules/noctalia.nix`).

## Where things are documented

- `desktop/CONTEXT.md`: glossary for module boundaries (portable /
  hardware-locked / opinionated modules, live-lane vs stable-lane dotfiles,
  shared `/home` with CachyOS). Read before moving modules or dotfile ownership.
- `CONTEXT.md` (root): glossary for the Claude Code TTS setup only.
- `docs/adr/`: decisions (two-commit rebuild, live-lane Claude config).
- `desktop/configs/niri/CLAUDE.md`: niri/noctalia config layout.

## Claude Code's own tools and box

`desktop/modules/home/claude-box.nix` defines two launchers:

- `claude` (default) runs the whole process inside Anthropic's sandbox
  runtime: file tools, Bash, hooks and MCP servers. Only the working
  directory, `/tmp`, the wiki and Claude's own state are writable; the rest of
  home is hidden; no sudo, ssh, nix daemon or session D-Bus; network is an
  allowlist in that file. `CLAUDE_BOXED=1` is set inside.
- `claude-host` has no box. Rebuilds and anything touching this machine need
  it; `claude-host --resume <id>` continues a boxed session. Its PATH is only
  the tool list, so `command -v claude` fails there too: test
  `$CLAUDE_BOXED`, never PATH, before calling a session boxed. Run
  `rebuild.sh` with the system dirs first:
  `PATH=/run/wrappers/bin:/run/current-system/sw/bin:$PATH ./rebuild.sh`.
  Without that, `nvd` can't find `nix-store`, and sudo resolves the
  claude-tools `nixos-rebuild`, which the NOPASSWD rule (pinned to
  `/run/current-system/sw/bin/nixos-rebuild`) doesn't match (2026-11-14).

`desktop/modules/home/librarian.nix` runs the llm-wiki librarian
(`configs/claude/agents/librarian.md`): a 15-min user timer gated on
`librarian-score`; `librarian-run --force` runs it by hand. Design and plan in
`docs/superpowers/`.

`desktop/modules/home/claude-tools.nix` is the full list of commands either
one can run by name. Never add agent tooling to `environment.systemPackages`.

- Boxed and missing a tool: `claude-request-tool <nixpkgs-attr> <reason>`. The
  host-side `claude-outbox` script validates the name, adds it to
  `claude-tools.nix`, commits, and notifies Noah with a Rebuild button.
- Unboxed (`claude-host`) and missing a tool: `nix shell nixpkgs#foo -c foo ...`
  or `nix run nixpkgs#foo -- ...`. Don't edit `claude-tools.nix` for it;
  that list is Noah's call (2026-11-16).

Update Claude with `nix flake update claude-code` in `desktop/`, check that
the input's diff only touches the version and hashes, then rebuild.

## Testing in the VM

```bash
nix build ~/nixos/desktop#nixosConfigurations.vm.config.system.build.vm
NIX_DISK_IMAGE=<scratchpad>/vm.qcow2 ./result/bin/run-nixos-vm-vm   # fresh disk
ssh -p 2223 noah@localhost
```

QEMU `screendump` fails ("no surface", GL display): log in via the monitor's
`sendkey`, then screenshot with `niri msg action screenshot-screen` over SSH.
State the desktop needs but the repo doesn't declare is tracked in
`docs/vm-undeclared-state.md`.

## Conventions

- `// ponytail:` comments mark deliberate simplifications/deferred work —
  read them before "fixing" something that looks incomplete.
- Don't rewrite unrelated generated dotfiles or machine-specific settings, and
  keep hardware-locked config out of portable modules (see
  `desktop/CONTEXT.md`).
- Format all `*.nix` with `alejandra` before committing.
