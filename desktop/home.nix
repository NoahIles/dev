{identity, ...}: {
  imports = [
    ./modules/home/apps.nix
    ./modules/home/programs.nix
    ./modules/home/dotfiles.nix
  ];

  home.username = identity.username;
  home.homeDirectory = identity.homeDirectory;
  home.stateVersion = "26.05";

  # ponytail: @home is shared with CachyOS, so most of ~/.config stays
  # canonical/loose (niri, noctalia, fish, …) via the live-lane symlinks in
  # modules/home/dotfiles.nix; migration to HM-managed files is piecemeal.
}
