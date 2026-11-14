# Noctalia — desktop shell + greeter. Opinionated module: everything noctalia
# needs (system services, greeter, binary cache, the HM shell unit, its
# config dirs, plugin deps, theme hooks into other apps) lives here so it can
# be swapped out in one place. Exception: the helium theme extension, baked
# into that package's override in modules/apps.nix.
{
  config,
  identity,
  pkgs,
  inputs,
  pkgs-unstable,
  ...
}: {
  imports = [inputs.noctalia-greeter.nixosModules.default];

  # noctalia + noctalia-greeter are compiled C++; upstream CI publishes them
  # here, built against the nixpkgs in upstream's own flake.lock. So their
  # inputs must not follow our nixpkgs (flake.nix). If they start compiling
  # again, check `nix flake metadata` shows their nixpkgs as upstream's pin;
  # removing a follows needs `nix flake update noctalia noctalia-greeter`
  # before the lock picks that pin up.
  nix.settings = {
    extra-substituters = ["https://noctalia.cachix.org"];
    extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
  };

  # noctalia-greeter scans /run/current-system/sw/share/wayland-sessions for
  # the session list; NixOS normally only hands the session files to a display
  # manager, so link them into the system path.
  environment.pathsToLink = ["/share/wayland-sessions"];
  # Compositors are per-compositor modules (modules/niri.nix, modules/umbriel.nix);
  # everything the greeter needs is here, session-agnostic.
  services.displayManager.noctalia-greeter = {
    enable = true;
    # ponytail: near-empty on purpose. Noctalia's Settings -> Security ->
    # "Sync Now" writes palette/wallpaper into sync.toml; a complete
    # declarative [appearance.palette] here would override it.
    settings.session.default = "umbriel";
    settings.user.default = identity.username;
  };
  services.greetd.settings.default_session.user = "greeter";

  # Default wallpaper for fresh installs; the seed below points here.
  # A fixed /etc path survives GC, unlike a raw store path in settings.toml.
  environment.etc."backgrounds/default.jpeg".source = ../assets/wallpaper.jpeg;

  # power-profiles widget
  services.power-profiles-daemon = {
    enable = true;
    package = pkgs-unstable.power-profiles-daemon;
  };
  # battery widget (reads battery/peripheral levels via UPower over DBus)
  services.upower.enable = true;

  environment.systemPackages = [
    config.services.displayManager.sessionData.desktops # for the greeter, see above
    # plugin backends
    (pkgs.callPackage ../pkgs/ai-usagebar.nix {}) # ai-usagebar plugin
    pkgs.bitwarden-cli # bitwarden plugin
    pkgs.wlr-randr # displays plugin: output on/off and scale on niri and umbriel
    pkgs.ddcutil # brightness on external monitors (brightness.enable_ddcutil)
  ];

  # DDC/CI over i2c for ddcutil. The package's udev rules tag the GPU's i2c
  # buses uaccess, so the seat user gets access without a group or re-login.
  hardware.i2c.enable = true;
  services.udev.packages = [pkgs.ddcutil];

  home-manager.users.${identity.username} = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.noctalia.homeModules.default];

    # Runs noctalia as a user unit (Restart=on-failure, own journal) instead of
    # niri's spawn-at-startup. `settings`/`customPalettes` stay unset on purpose:
    # setting either makes the module declare xdg.configFile."noctalia/config.toml",
    # which collides with the whole-directory live-lane symlink below.
    # Real user config lives in ~/.local/state/noctalia/settings.toml, which the
    # module never touches.
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };
    # Apps opened from the launcher land in this unit's cgroup; some (jellyfin-
    # desktop) ignore SIGTERM and stalled every reboot for the 90s default.
    systemd.user.services.noctalia.Service.TimeoutStopSec = "5s";

    # live lane, same as modules/home/dotfiles.nix.
    # ponytail: hardcoded — builtins.toString resolves to /nix/store in flakes
    xdg.configFile."noctalia".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/desktop/configs/noctalia";

    # Seed once, GUI owns it afterwards. noctalia's settings GUI rewrites
    # ~/.local/state/noctalia/settings.toml in place, and @home is shared with
    # CachyOS, so HM must not own it (a store symlink would be read-only and
    # would clobber CachyOS-side edits). Copy the snapshot only when the file
    # is missing; re-snapshot configs/noctalia-seed/settings.toml by hand.
    # .setup-complete skips the first-run wizard, which would overwrite it.
    # The snapshot's wallpaper paths point at ~/Pictures folders a fresh box
    # lacks, so swap them for the default wallpaper above.
    home.activation.noctaliaSeed = let
      seed = pkgs.runCommand "noctalia-seed.toml" {} ''
        sed -e 's|"[^"]*_Wallpapers/[^"]*"|"/etc/backgrounds/default.jpeg"|g' \
            -e 's|"[^"]*_Wallpapers"|"/etc/backgrounds"|g' \
            ${../configs/noctalia-seed/settings.toml} > $out
      '';
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        d="$HOME/.local/state/noctalia"
        if [ ! -e "$d/settings.toml" ] && [ ! -L "$d/settings.toml" ]; then
          run install -Dm644 ${seed} "$d/settings.toml"
          run touch "$d/.setup-complete"
        fi
      '';

    # Point qtct at noctalia's generated palette; the rest of qt lives in
    # modules/home/programs.nix and merges with this.
    qt.qt5ctSettings.Appearance = {
      custom_palette = true;
      color_scheme_path = "${config.xdg.configHome}/qt5ct/colors/noctalia.conf";
    };
    qt.qt6ctSettings.Appearance = {
      custom_palette = true;
      color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/noctalia.conf";
    };

    # vesktop's settings.json is mostly its own runtime state (plugin toggles,
    # cloud auth) — don't own the whole file, just make sure our theme is
    # enabled. Patches in place, leaves everything else untouched.
    home.activation.vesktopNoctaliaTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      f="$HOME/.config/vesktop/settings/settings.json"
      if [ -f "$f" ]; then
        ${pkgs.jq}/bin/jq '.enabledThemes = ((.enabledThemes // []) + ["noctalia.theme.css"] | unique)' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      fi
    '';
  };
}
