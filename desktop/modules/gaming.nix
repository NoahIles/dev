{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  # Upstream recipe (umbriel docs/user/streaming.md): a virtual output per
  # session at the client's resolution and fps, destroyed afterwards.
  # ponytail: umbriel only; under niri `output-create` fails and the stream won't start.
  umbrielOutput = pkgs.writeShellApplication {
    name = "sunshine-umbriel-output";
    runtimeInputs = [pkgs.jq config.programs.umbriel.package];
    text = ''
      name=sunshine
      case "$1" in
        create)
          umbriel output-destroy "$name" >/dev/null 2>&1 || true
          umbriel output-create "$name" \
            "''${SUNSHINE_CLIENT_WIDTH:-1920}x''${SUNSHINE_CLIENT_HEIGHT:-1080}@''${SUNSHINE_CLIENT_FPS:-60}" >/dev/null
          ;;
        remove)
          # Let the app's undo close its windows, then move stragglers off
          # explicitly so umbriel doesn't remember "sunshine" as their home.
          i=0
          while [ "$i" -lt 25 ]; do
            left="$(umbriel windows --json |
              jq --arg out "$name:" '[.[] | select(.workspace | startswith($out))] | length')"
            [ "$left" = 0 ] && break
            sleep 0.2
            i=$((i + 1))
          done
          target="$(umbriel workspaces --json |
            jq -r --arg out "$name" '[.[] | select(.output != $out and .active)]
              | (map(select(.focused)) + .) | first | "\(.name)/\(.output)" // empty')"
          for id in $(umbriel windows --json |
            jq -r --arg out "$name:" '.[] | select(.workspace | startswith($out)) | .id'); do
            [ -n "$target" ] || break
            umbriel msg window-focus "$id"
            umbriel msg window-move-to-workspace-silent "$target"
          done
          umbriel output-destroy "$name" >/dev/null 2>&1 || true
          ;;
      esac
    '';
  };
in {
  services.sunshine = {
    enable = true;
    autoStart = true;
    # Stock build can't dlopen libcuda, so NVENC fails and it falls back to x264.
    package = pkgs.sunshine.override {cudaSupport = true;};
    settings = {
      capture = "wlr";
      output_name = "sunshine";
      global_prep_cmd = builtins.toJSON [
        {
          do = "${lib.getExe umbrielOutput} create";
          undo = "${lib.getExe umbrielOutput} remove";
        }
      ];
    };
  };
  # Stream ports only (base 47989); the web UI on 47990 stays localhost-only,
  # since whoever reaches it first sets the admin password.
  networking.firewall = {
    allowedTCPPorts = [47984 47989 48010];
    allowedUDPPorts = [47998 47999 48000 48002 48010];
  };

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
