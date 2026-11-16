{lib, ...}: {
  imports = [../../modules/media.nix];

  # ponytail: serverConfig stays empty on purpose. A non-empty one makes the
  # module overwrite qBittorrent.conf on every start; the copied profile
  # (profileDir/qBittorrent/{config,data}) is the config.
  services.qbittorrent = {
    enable = true;
    group = "media_share";
    webuiPort = 8090;
    torrentingPort = 3161;
    openFirewall = true;
    extraArgs = ["--confirm-legal-notice"];
  };
  networking.firewall.allowedUDPPorts = [3161];

  # New files must be group-writable (media-state-swap.md, option C).
  systemd.services.qbittorrent.serviceConfig.UMask = lib.mkForce "0002";

  system.stateVersion = "26.05";
}
