{
  pkgs,
  pkgs-unstable,
  ...
}: let
  # ponytail: not in nixpkgs (nor any flake) — only AUR/Void package it.
  # Hash matches the AUR PKGBUILD's sha256 for 0.5.0.
  wooting-bg-service = pkgs.appimageTools.wrapType2 rec {
    pname = "wooting-bg-service";
    version = "0.5.0";
    src = pkgs.fetchurl {
      url = "https://api.wooting.io/public/bg-service/download-installer?target=linux&version=${version}";
      hash = "sha256-e5NQ9rExdmvobXMEQDfrnU0ofIDOd14AEfH7SkRC6VU=";
      name = "${pname}-${version}.AppImage";
    };
  };
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
