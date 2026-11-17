# Jellyfin, moved from docker CT 110 (linuxserver image, 12.0.0).
# The old layout is kept byte for byte so the copied state works untouched:
#  - the DB stores the container's paths: /config/... (images, metadata) and
#    /data/{movies,tvshows,Anime,books,ssl_certs} (libraries);
#  - the CT mounts /Pool-1/media at /media_root (same as 110) and the /data
#    paths are bind mounts of its subdirs.
{
  lib,
  pkgs,
  unstable,
  ...
}: {
  imports = [../../modules/media.nix];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    # Stable has 10.11.x; a copied 12.x DB cannot go back. See flake.nix.
    package = unstable.jellyfin;
    group = "media_share";
    dataDir = "/config/data";
    configDir = "/config";
    cacheDir = "/config/cache";
    logDir = "/config/log";
    # encoding.xml is copied from 110; keep it (forceEncodingConfig stays off).
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
  };

  # Files next to media (trickplay, images) must be group-writable like the
  # other media services (media-state-swap.md, option C).
  systemd.services.jellyfin.serviceConfig.UMask = lib.mkForce "0002";
  # Mesa's VA-API driver (AMD Phoenix, radeonsi) for the passed-through iGPU.
  systemd.services.jellyfin.environment.LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
  hardware.graphics.enable = true;
  users.users.jellyfin = {
    # Old Jellyfin ran as PUID 10000 and owns ~47k artwork files under /data;
    # same uid means no chown of media and the copied /config needs none either.
    uid = 10000;
    extraGroups = ["render" "video"];
  };

  fileSystems = let
    bind = sub: {
      device = "/media_root/${sub}";
      fsType = "none";
      options = ["bind"];
    };
  in {
    "/data/movies" = bind "Movies";
    "/data/tvshows" = bind "TV-Shows";
    "/data/Anime" = bind "Anime";
    "/data/books" = bind "Books";
    "/data/ssl_certs" = bind "ssl_certs";
  };

  environment.systemPackages = [pkgs.libva-utils];

  system.stateVersion = "26.05";
}
