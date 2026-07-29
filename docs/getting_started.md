# Getting Started

> WIP -- this doc is a fragment; sections will be filled in as the setup stabilises.

## Gotchas

### Live dotfile symlinks must use a hardcoded path

The `live` helper in `desktop/modules/home/dotfiles.nix` uses
`mkOutOfStoreSymlink` to symlink `~/.config/<app>` to the repo checkout so
hand-edits hot-reload without a rebuild. This requires a **string** containing
the real filesystem path -- not a Nix path expression.

In flake mode, any Nix path (e.g. `../../configs`) is copied into
`/nix/store` at eval time. `builtins.toString` on that path gives you the
store path, not the original location on disk. Flakes are pure by design --
there is no built-in way for a flake to discover where its own source lives.

This means `configsDir` must be hardcoded:

```nix
configsDir = "${config.home.homeDirectory}/nixos/desktop/configs";
```

If the repo moves from `~/nixos`, update this string. Alternatives
(`--impure` + `builtins.getEnv`, passing the path via `specialArgs` from
`rebuild.sh`) exist but aren't worth the complexity unless the repo location
actually varies.

**Symptom if broken:** apps like fish spam `Read-only file system (os error
30)` because their config dir points into `/nix/store`.
