{lib, ...}: {
  imports = [../../modules/media.nix];

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media_share";
  };

  # New files must be group-writable (media-state-swap.md, option C).
  systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";

  system.stateVersion = "26.05";
}
