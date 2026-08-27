{
  pkgs,
  pkgs-unstable,
  identity,
  config,
  ...
}: {
  # noctalia-greeter scans /run/current-system/sw/share/wayland-sessions for
  # the session list; NixOS normally only hands the session files to a display
  # manager, so link them into the system path.
  environment.pathsToLink = ["/share/wayland-sessions"];
  environment.systemPackages = [
    pkgs.adwaita-qt6
    pkgs.papirus-icon-theme
    config.services.displayManager.sessionData.desktops
  ];
  services.flatpak.enable = true;
  # Compositors are per-compositor modules (modules/niri.nix, modules/umbriel.nix);
  # everything the greeter needs is here, session-agnostic.
  programs.noctalia-greeter = {
    enable = true;
    # ponytail: near-empty on purpose. Noctalia's Settings -> Security ->
    # "Sync Now" writes palette/wallpaper into sync.toml; a complete
    # declarative [appearance.palette] here would override it.
    settings.session.default = "niri";
    settings.user.default = identity.username;
  };
  services.greetd.settings.default_session.user = "greeter";

  # audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # power profile switching (Noctalia's power-profiles widget needs this)
  services.power-profiles-daemon = {
    enable = true;
    package = pkgs-unstable.power-profiles-daemon;
  };

  # fan and cooling device control GUI plus daemon.
  # Qt5 and Qt6 apps can't share one QT_QPA_PLATFORMTHEME=qtct value (the
  # plugin binaries are named qt5ct/qt6ct respectively), and home.nix's HM
  # qt config only sets the Qt5 name — so this Qt6 app needs its own
  # wrapper arg to pick up qt6ct (and the noctalia dark palette with it).
  nixpkgs.overlays = [
    (final: prev: {
      coolercontrol =
        prev.coolercontrol
        // {
          coolercontrol-gui = prev.coolercontrol.coolercontrol-gui.overrideAttrs (old: {
            qtWrapperArgs = (old.qtWrapperArgs or []) ++ ["--set QT_QPA_PLATFORMTHEME qt6ct"];
          });
        };
    })
  ];
  programs.coolercontrol.enable = true;

  # battery widget (Noctalia reads battery/peripheral levels via UPower over DBus)
  services.upower = {
    enable = true;
    package = pkgs-unstable.upower;
  };

  # swaylock needs a PAM entry to actually unlock
  security.pam.services.swaylock = {};

  # pkexec needs the setuid wrapper (polkit.enable) and an auth agent
  # to show the password prompt (soteria works on any Wayland compositor)
  security.polkit.enable = true;
  # security.polkit.enablePkexecWrapper = true; # opt-in since nixpkgs 26.05
  security.soteria.enable = true;

  # nautilus smb:// (and trash/mtp) needs gvfs
  services.gvfs.enable = true;
  # right-click "Open in Terminal" in nautilus
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    EDITOR = "zeditor";
    SUDO_EDITOR = "zeditor";
    STEAM_EDITOR = "zeditor";
    # niri keybind Mod+Return spawns "$TERMINAL"
    TERMINAL = "alacritty";
    # niri keybind Mod+E spawns "$FILE_MANAGER"
    FILE_MANAGER = "nautilus";
    # GTK and Qt theming are selected via Home Manager so Noctalia's generated
    # palette files can provide app colors.
    # Prevent podman-compose from emitting messages; see podman-compose(1)
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };
}
