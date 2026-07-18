{
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
in {
  home.packages = with pkgs; [
    imv # Image viewer
    zed-editor # Text editor
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    spotify
    pkgs-unstable.mailspring
    # flake ships the binary as `zen-beta`; alias it so `zen-browser` (used by
    # niri keybinds) resolves. This is the official stable Zen release.
    (pkgs.writeShellScriptBin "zen-browser" ''exec zen-beta "$@"'')
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default # Shell
    (jellyfin-desktop.overrideAttrs (old: {
      # ponytail: NVIDIA + native Wayland fails to composite mpv's embedded
      # video surface (white screen on playback) — force XWayland instead.
      qtWrapperArgs = old.qtWrapperArgs ++ ["--set QT_QPA_PLATFORM xcb"];
    }))
    vesktop
    teamspeak6-client

    # niri config runtime deps
    pavucontrol
    fuzzel
    swaylock
    brightnessctl
    playerctl
    wl-clipboard
    nautilus
    xwayland-satellite
    tailscale
  ];
}
