{
  pkgs,
  pkgs-unstable,
  ...
}: {
  environment.systemPackages = with pkgs; [
    protonup-qt
    unzip # protonup-qt shells out to it for .zip releases
    pkgs-unstable.mangohud
    pkgs-unstable.vulkan-tools
    pkgs-unstable.osu-lazer-bin
  ];

  programs.steam = {
    enable = true;
    # extest XTEST shim so the Steam Controller works / cursor isn't invisible on wayland
    # `extest.enable` only preloads the 32-bit libextest.so.
    extest.enable = false;
    package = pkgs.steam.override {
      extraEnv.LD_PRELOAD = "${pkgs.pkgsi686Linux.extest}/lib/libextest.so:${pkgs.extest}/lib/libextest.so";
      extraPkgs = p: [p.gamemode p.osu-lazer-bin p.mangohud];
    };
    protontricks.enable = true;
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        desiredgov = "performance";
        ioprio = 0;
        softrealtime = "auto";
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        nv_powermizer_mode = 1;
      };
    };
  };
}
