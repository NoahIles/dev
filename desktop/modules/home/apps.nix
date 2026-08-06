{
  pkgs,
  pkgs-unstable,
  inputs,
  config,
  ...
}: {
  # ponytail: pkgs-unstable passed via extraSpecialArgs — was:
  # pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
  home.packages = with pkgs; [
    # ponytail: carries the hicolor index.theme into *this* profile — without it
    # noctalia falls back to a size list capped at 256 and misses zed's 512px icon.
    hicolor-icon-theme
    hyprpicker # color picker still need to setup bind
    pastel # paint probably move to another file
    zathura # PDF Viewer
    imv # Image viewer
    zed-editor # Text editor
    (inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium.override {
      flags = ["--load-extension=${config.home.homeDirectory}/.cache/noctalia/helium-theme"];
    }) # Browser trial
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
      # ...which means niri sees the XWayland WM_CLASS (`jellyfin-desktop`),
      # not the Wayland app_id, so noctalia's dock can't match the entry.
      postInstall =
        (old.postInstall or "")
        + ''
          substituteInPlace $out/share/applications/*.desktop \
            --replace-fail StartupWMClass=org.jellyfin.JellyfinDesktop \
                           StartupWMClass=jellyfin-desktop
        '';
    }))
    vesktop
    pkgs-unstable.discord
    teamspeak6-client
    qbittorrent
    mpv
    yazi
    gpu-screen-recorder-gtk

    # niri config runtime deps
    pavucontrol
    fuzzel
    swaylock-effects
    brightnessctl
    playerctl
    wl-clipboard
    nautilus
    xwayland-satellite
    # tailscale # Vendor hash broken at the moment
    wvkbd
  ];

  # Minecraft
  programs.prismlauncher = {
    enable = true;
    extraPackages = [];
    settings = {
      ApplicationTheme = "Dark";
      EnableFeralGamemode = "false";
      MaxMemAlloc = 4095;
      Language = "en_US";
      PermGen = 255;
      CloseAfterLaunch = true;
    };
  };
}
