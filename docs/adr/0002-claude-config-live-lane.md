# Claude Code config is live-lane, not a home-manager module

`modules/home/claude.nix` symlinks `configs/claude/` into `~/.claude` with
`mkOutOfStoreSymlink` and nothing else. It deliberately does not use
home-manager's `programs.claude-code` module, and does not deliver settings
through `/etc/claude-code/managed-settings.json`.

## Why

Claude Code writes its own `settings.json` at runtime — `/model`, `/effort`,
plugin toggles, user-scope "always allow" rules. `programs.claude-code.settings`
renders that file into the Nix store and symlinks it read-only, which fights
those writes. Verified 2026-09-19 on v2.1.278: Claude resolves a symlinked
`settings.json` and renames a temp file over the *target*, so a live-lane link
into this checkout takes the writes and shows them as git diffs instead. Drift
becomes visible rather than impossible, which is the same bargain
`dotfiles.nix` already makes with noctalia.

## Considered options

- **`programs.claude-code`.** Rejected: read-only `settings.json` (above), and
  its `plugins`/`mcpServers` options only take effect through a wrapper around
  a nix-provided `claude` package. The binary here comes from the native
  installer so it keeps auto-updating.
- **Managed settings in `/etc/claude-code/`.** Read-only by design and merged
  with the user's own file, which fits the enforced parts well. Rejected
  because it's a NixOS-system mechanism: the same module has to work on
  NixOS-WSL and on a Proxmox host, where home-manager may be standalone.
- **Copy-on-activation** (the noctalia dotfile pattern). Rejected: a copy makes
  runtime changes invisible to git, which is the drift this is meant to stop.

## Consequences

- `~/nixos` must be cloned on every host before home-manager switches, or the
  links dangle. Same for `~/Documents/llm-wiki`, which `autoMemoryDirectory`
  and the sync hook point at.
- Runtime settings changes land in the working tree, and `rebuild.sh`'s
  `git commit -a` sweeps them into the next rebuild commit.
- One `settings.json` serves every host, so host-specific hooks must no-op
  where their tool is missing (`command -v X && exec X`).
- `~/nixos` is public. Anything added to `configs/claude/` is published on the
  next push.
