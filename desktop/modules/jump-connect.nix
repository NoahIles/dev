{pkgs, ...}: let
  jump-connect = pkgs.callPackage ../pkgs/jump-connect.nix {};
in {
  # Jump Desktop Connect: remote-desktop host. Sign in once with
  # `jumpconnect --signin` (or from its window).
  # ponytail: no VDI (headless X11 sessions; needs Xorg + a Debian-style PAM
  # stack) and no self-updater; bump the package instead.
  environment.systemPackages = [jump-connect]; # desktop entry, icon, polkit action
  systemd.packages = [jump-connect];
  systemd.tmpfiles.packages = [jump-connect];
  services.udev.packages = [jump-connect];
  boot.kernelModules = ["uinput"];

  # what upstream's sysusers.d/jump.conf would create
  users.groups.jump = {};
  users.users.jump-rtc = {
    isSystemUser = true;
    group = "jump";
    home = "/run/jump-connect";
  };

  # [Install] sections in systemd.packages are ignored, so wire these by hand
  systemd.services.jump-connect.wantedBy = ["multi-user.target"];
  systemd.user.services.jump-agent = {
    wantedBy = ["graphical-session.target"];
    # Qt 6.11 is bundled with only the xcb platform plugin: run on Xwayland
    # and keep the session's nixpkgs Qt plugins/QML/theme from being loaded.
    environment.QT_QPA_PLATFORM = "xcb";
    serviceConfig.UnsetEnvironment = ["QT_PLUGIN_PATH" "QML2_IMPORT_PATH" "QT_QPA_PLATFORMTHEME"];
  };
}
