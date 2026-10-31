{config, ...}: let
  # live-lane: symlink to repo checkout so hand-edits hot-reload. The VM gets
  # its checkout seeded on first boot (vm.nix), so it links the same way.
  # ponytail: hardcoded — builtins.toString resolves to /nix/store in flakes
  configsDir = "${config.home.homeDirectory}/nixos/desktop/configs";
  live = name: {source = config.lib.file.mkOutOfStoreSymlink "${configsDir}/${name}";};
in {
  # Everything HM merely *points at*. The canonical content is the file in
  # configs/ — edit that directly, no rebuild needed on the live lane.
  # Anything HM generates from Nix options lives in programs.nix.

  xdg.configFile."niri" = live "niri";
  xdg.configFile."umbriel" = live "umbriel";
  xdg.configFile."noctalia" = live "noctalia";
  xdg.configFile."fish" = live "fish";
  xdg.configFile."zed" = live "zed";
  xdg.configFile."starship.toml" =
    (live "starship/starship.toml")
    // {force = true;};
  xdg.configFile."ghostty/config" = live "ghostty/config";

  # stable lane: store-backed, rebuild to change. Per-file on purpose —
  # noctalia's theming writes generated files beside these; never manage
  # the whole dir.
  xdg.configFile."fuzzel/fuzzel.ini".source = ../../configs/fuzzel/fuzzel.ini;
  xdg.configFile."ghostty/shaders/rain.glsl".source = ../../configs/ghostty/shaders/rain.glsl;
  xdg.configFile."ghostty/shaders/subtle-crt.glsl".source = ../../configs/ghostty/shaders/subtle-crt.glsl;
  xdg.configFile."swaylock/config".source = ../../configs/swaylock/config;
  xdg.configFile."mpv/mpv.conf".source = ../../configs/mpv/mpv.conf;
  xdg.configFile."television/config.toml".source = ../../configs/television/config.toml;
  # tokens are NOT here — see the header of that file.
  xdg.configFile."managarr/config.yml".source = ../../configs/managarr/config.yml;
}
