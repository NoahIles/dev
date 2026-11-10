{pkgs, ...}: {
  # ponytail: nixpkgs has the package but no services.apt-cacher-ng module,
  # so this is a bare unit. Settings are acng.conf keys passed as args; the
  # package's own acng.conf supplies the rest (mirror remaps, SupportDir).
  systemd.services.apt-cacher-ng = {
    description = "apt-cacher-ng package cache proxy";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      ExecStart = "${pkgs.apt-cacher-ng}/bin/apt-cacher-ng ForeGround=1 Port=3142 CacheDir=/var/cache/apt-cacher-ng LogDir=/var/log/apt-cacher-ng SocketPath=/run/apt-cacher-ng/socket";
      DynamicUser = true;
      CacheDirectory = "apt-cacher-ng";
      LogsDirectory = "apt-cacher-ng";
      RuntimeDirectory = "apt-cacher-ng";
      Restart = "on-failure";
    };
  };
  networking.firewall.allowedTCPPorts = [3142];

  system.stateVersion = "26.05";
}
