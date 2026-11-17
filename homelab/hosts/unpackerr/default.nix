# Unpackerr, moved from docker CT 110 (golift/unpackerr 0.16.1). No NixOS
# module exists, so this is a plain unit; config is the same UN_* env vars.
# The *arr API keys live in /etc/unpackerr/env (root 0600, out of band). The
# unit only starts once that file exists, so the build can't double-extract
# beside the old container before cutover.
{unstable, ...}: {
  imports = [../../modules/media.nix];

  # Old container ran as 1000:10000; its extractions in Downloads are uid 1000.
  users.users.unpackerr = {
    isSystemUser = true;
    uid = 1000;
    group = "media_share";
  };

  systemd.services.unpackerr = {
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = "/etc/unpackerr/env";
    environment = {
      UN_SONARR_0_URL = "http://sonarr.home:8989";
      UN_SONARR_0_PATHS_0 = "/media/Downloads/tv-sonarr/";
      UN_SONARR_0_PROTOCOLS = "torrent";
      UN_RADARR_0_URL = "http://radarr.home:7878";
      UN_RADARR_0_PATHS_0 = "/media/Downloads/radarr/";
      UN_RADARR_0_PROTOCOLS = "torrent";
      UN_FOLDER_0_PATH = "/media/Downloads";
      UN_FOLDER_0_DELETE_AFTER = "10m";
      UN_FILE_MODE = "0664";
      UN_DIR_MODE = "0775";
      UN_START_DELAY = "1m";
      UN_INTERVAL = "2m";
      UN_RETRY_DELAY = "5m";
      UN_MAX_RETRIES = "3";
      UN_PARALLEL = "1";
    };
    serviceConfig = {
      # 0.16.1 like the old container; stable has 0.15.2. Stateless, but no reason to step back.
      ExecStart = "${unstable.unpackerr}/bin/unpackerr";
      EnvironmentFile = "/etc/unpackerr/env";
      User = "unpackerr";
      Group = "media_share";
      UMask = "0002";
      Restart = "on-failure";
    };
  };

  system.stateVersion = "26.05";
}
