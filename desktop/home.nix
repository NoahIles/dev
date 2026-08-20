{
  identity,
  inputs,
  ...
}: {
  imports = [
    ./modules/home/programs.nix
    ./modules/home/dotfiles.nix
    inputs.noctalia.homeModules.default
  ];

  home.username = identity.username;
  home.homeDirectory = identity.homeDirectory;
  home.stateVersion = "26.05";

  # ponytail: @home is shared with CachyOS, so most of ~/.config stays
  # canonical/loose (niri, noctalia, fish, …) via the live-lane symlinks in
  # modules/home/dotfiles.nix; migration to HM-managed files is piecemeal.

  # Runs noctalia as a user unit (Restart=on-failure, own journal) instead of
  # niri's spawn-at-startup. `settings`/`customPalettes` stay unset on purpose:
  # setting either makes the module declare xdg.configFile."noctalia/config.toml",
  # which collides with the whole-directory live-lane symlink in dotfiles.nix.
  # Real user config lives in ~/.local/state/noctalia/settings.toml, which the
  # module never touches.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };
}
