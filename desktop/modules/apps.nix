{
  identity,
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # GUI applications and the runtime deps the niri config shells out to.
  # Deliberately separate from desktop.nix, which is the desktop *environment*
  # (compositor, greeter, portals, pipewire) rather than things you launch.
  environment.systemPackages = with pkgs; [
    hyprpicker # color picker still need to setup bind
    pastel # paint probably move to another file
    inputs.swash.packages.${pkgs.stdenv.hostPlatform.system}.default # Screenshot annotator
    zathura # PDF Viewer
    imv # Image viewer
    zed-editor # Text editor
    (inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium.override {
      flags = ["--load-extension=${identity.homeDirectory}/.cache/noctalia/helium-theme"];
    }) # Browser trial
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    (callPackage ../pkgs/ai-usagebar.nix {}) # AI plan usage; backs the noctalia ai-usagebar plugin
    spotify
    (pkgs-unstable.mailspring.overrideAttrs (old: {
      # ponytail: gnome-keyring *is* running, but Electron picks its password
      # backend from XDG_CURRENT_DESKTOP — `niri` isn't in its list, so it falls
      # back to plaintext and Mailspring refuses to store the password. Name the
      # backend explicitly.
      preFixup =
        (old.preFixup or "")
        + ''
          gappsWrapperArgs+=(--add-flags --password-store=gnome-libsecret)
        '';
    }))
    # flake ships the binary as `zen-beta`; alias it so `zen-browser` (used by
    # niri keybinds) resolves. This is the official stable Zen release.
    (pkgs.writeShellScriptBin "zen-browser" ''exec zen-beta "$@"'')
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
    # ponytail: FHS/bwrap sandbox (nixpkgs default since 1.0.153) breaks
    # screenshare — PipeWire format negotiation fails with "no more input
    # formats" ~50ms in. Drop the override once upstream fixes it.
    (pkgs-unstable.discord.override {useFHSEnv = false;})
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
    obsidian
  ];
}
