{...}: {
  # niri session, autologin straight into it
  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "niri-session";
      user = "noah";
    };
  };

  # audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # power profile switching (Noctalia's power-profiles widget needs this)
  services.power-profiles-daemon.enable = true;

  # battery widget (Noctalia reads battery/peripheral levels via UPower over DBus)
  services.upower.enable = true;

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
    EDITOR = "zeditor";
    SUDO_EDITOR = "zeditor";
    STEAM_EDITOR = "zeditor";
    # niri keybind Mod+Return spawns "$TERMINAL"
    TERMINAL = "alacritty";
    # niri keybind Mod+E spawns "$FILE_MANAGER"
    FILE_MANAGER = "nautilus";
    # dconf gtk-theme is cachyos-nord (shared home, not installed here), so GTK3
    # apps (solaar etc.) fell back to light Adwaita. Force dark NixOS-side only.
    GTK_THEME = "Adwaita:dark";
    # Prevent podman-compose from emitting messages; see podman-compose(1)
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };
}
