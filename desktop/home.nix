{...}: {
  imports = [
    ./modules/home/apps.nix
    ./modules/home/dev.nix
    ./modules/home/terminal.nix
    ./modules/home/dotfiles.nix
    ./modules/home/audio.nix
  ];

  home.username = "noah";
  home.homeDirectory = "/home/noah";
  home.stateVersion = "26.05";

  # ponytail: @home is shared with CachyOS, so most of ~/.config stays
  # canonical/loose (niri, noctalia, fish, …) via the live-lane symlinks in
  # modules/home/dotfiles.nix; migration to HM-managed files is piecemeal.
}
