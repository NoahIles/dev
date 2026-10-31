{
  pkgs,
  pkgs-unstable,
  ...
}: {
  environment.systemPackages = with pkgs; [
    protonup-qt
    pkgs-unstable.mangohud
    pkgs-unstable.vulkan-tools
    pkgs-unstable.osu-lazer-bin
    pkgs-unstable.wheelwizard
    dolphin-emu
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

  # libgamemodeauto dlopens "libgamemode.so" by bare name and relies on
  # gamemoderun's LD_LIBRARY_PATH, which pressure-vessel (Steam Linux Runtime)
  # replaces. /nix/store is visible in the container, so bake the lib dir into
  # RUNPATH and the game process itself registers.
  nixpkgs.overlays = [
    (final: prev: {
      gamemode = prev.gamemode.overrideAttrs (old: {
        postFixup =
          (old.postFixup or "")
          + ''
            patchelf --add-rpath $lib/lib $lib/lib/libgamemodeauto.so.0.0.0
          '';
      });
    })
  ];

  programs.gamemode = {
    enable = true;
    settings = {
      # ponytail: priorities are ananicy-cpp's job (cachyos rules give cs2 nice -5).
      # gamemode refuses to renice/ioprio a process ananicy already touched, and
      # SCHED_ISO doesn't exist on mainline kernels, so those knobs only logged errors.
      general = {
        desiredgov = "performance";
        ioprio = "off";
        softrealtime = "off";
        renice = 0;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        nv_powermizer_mode = 1;
      };
    };
  };
}
