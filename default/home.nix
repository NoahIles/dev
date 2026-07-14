{
  pkgs,
  inputs,
  ...
}: {
  home.username = "noah";
  home.homeDirectory = "/home/noah";
  home.stateVersion = "25.05";

  # ponytail: packages only — @home is shared with CachyOS, so HM manages
  # NO files here. ~/.config (niri, noctalia, fish, …) stays canonical on
  # the shared home; the vm/ profile is the one that deploys dotfiles.
  home.packages = with pkgs; [
    # apps
    imv # Image viewer
    ghostty # Terminal
    alacritty # Terminal
    zed-editor # Text editor
    inputs.zen-browser.packages.${pkgs.system}.default
    # flake ships the binary as `zen-beta`; alias it so `zen-browser` (used by
    # niri keybinds) resolves. This is the official stable Zen release.
    (pkgs.writeShellScriptBin "zen-browser" ''exec zen-beta "$@"'')
    inputs.noctalia.packages.${pkgs.system}.default # Shell
    (pkgs.writeShellScriptBin "game-performance" ''exec gamemode "$@"'')

    vesktop

    # dev
    git
    mise

    # niri config runtime deps
    fuzzel
    swaylock
    brightnessctl
    playerctl
    wl-clipboard
    nautilus
    xwayland-satellite
  ];
}
