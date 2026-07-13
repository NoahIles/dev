{ pkgs, inputs, ... }:

{
  home.username = "noah";
  home.homeDirectory = "/home/noah";
  home.stateVersion = "25.05";

  # ponytail: packages only — @home is shared with CachyOS, so HM manages
  # NO files here. ~/.config (niri, noctalia, fish, …) stays canonical on
  # the shared home; the vm/ profile is the one that deploys dotfiles.
  home.packages = with pkgs; [
    # apps
    ghostty
    alacritty
    zed-editor
    inputs.zen-browser.packages.${pkgs.system}.default
    inputs.noctalia.packages.${pkgs.system}.default

    # dev
    git
    mise

    # niri config runtime deps
    fuzzel
    swaylock
    brightnessctl
    playerctl
    jq
    wl-clipboard
    nautilus
    xwayland-satellite
  ];
}
