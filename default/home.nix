{ pkgs, config, inputs, ... }:

{
  home.username = "noah";
  home.homeDirectory = "/home/noah";
  home.stateVersion = "25.05";

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
  ];

  programs.fish.enable = true;

  # ponytail: copied, not symlinked — noctalia rewrites settings.json and
  # niri/noctalia.kdl at runtime, so these must stay user-writable.
  # Rebuilds overwrite runtime changes; edit the repo copy instead.
  home.activation.dotfiles = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.config
    cp -rfT ${./dotfiles/niri} $HOME/.config/niri
    cp -rfT ${./dotfiles/noctalia} $HOME/.config/noctalia
    chmod -R u+w $HOME/.config/niri $HOME/.config/noctalia
  '';
}
