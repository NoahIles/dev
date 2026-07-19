{pkgs, ...}: {
  programs.steam = {
    enable = true;
    # extest XTEST shim so the Steam Controller works / cursor isn't invisible on wayland
    # `extest.enable` only preloads the 32-bit libextest.so.
    extest.enable = false;
    package = pkgs.steam.override {
      extraEnv.LD_PRELOAD = "${pkgs.pkgsi686Linux.extest}/lib/libextest.so:${pkgs.extest}/lib/libextest.so";
    };
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        softrealtime = "auto";
        renice = 10;
      };
    };
  };

  programs.prismlauncher = {
    enable = true;
    extraPackages = [];
    settings = {
      ApplicationTheme = "Dark";
      EnableFeralGamemode = "true";
      MaxMemAlloc = 4096;
      Language = "en_US";
      PermGen = 256;
      CloseAfterLaunch = false;
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "game-performance" ''exec gamemoderun "$@"'')
  ];
}
