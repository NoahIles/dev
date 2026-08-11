{
  pkgs,
  pkgs-unstable,
  pkgs-wooting,
  ...
}: let
  # wooting-bg-service: tracking the open, unmerged nixpkgs PR
  # (NixOS/nixpkgs#529138) via the wooting-nixpkgs flake input. Drop this
  # input and use pkgs.wooting-bg-service once that PR merges.
  wooting-bg-service = pkgs-wooting.wooting-bg-service;
in {
  # ponytail: not hardware.wooting.enable — that pulls stable's wootility
  # (5.3.1) into systemPackages and would collide with the unstable one.
  services.udev.packages = [pkgs.wooting-udev-rules];
  environment.systemPackages = [
    pkgs-unstable.wootility # 5.4.1
    wooting-bg-service
  ];

  systemd.user.services.wooting-bg-service = {
    description = "Wooting Background Service";
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${wooting-bg-service}/bin/wooting-bg-service";
      Restart = "on-failure";
    };
  };
}
