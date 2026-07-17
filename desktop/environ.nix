{...}: {
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
