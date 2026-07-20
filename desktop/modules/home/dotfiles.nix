{
  config,
  pkgs,
  ...
}: let
  # live-lane dotfiles: symlink to the repo checkout (not the store) so
  # hand-edits hot-reload and GUI writes land as git diffs. Dangles if the
  # repo isn't at ~/nixos — programs then fall back to defaults.
  configsDir = "${config.home.homeDirectory}/nixos/desktop/configs";
  live = name: {source = config.lib.file.mkOutOfStoreSymlink "${configsDir}/${name}";};
in {
  xdg.configFile."niri" = live "niri";
  xdg.configFile."noctalia" = live "noctalia";
  xdg.configFile."fish" = live "fish";
  xdg.configFile."zed" = live "zed";
  # per-file, not the whole vesktop dir — it's full of runtime junk
  # (sessionData, Crashpad, generated theme css) that must stay unmanaged.
  xdg.configFile."vesktop/settings/settings.json" = live "vesktop/settings/settings.json";

  # stable lane: store-backed, rebuild to change. Per-file on purpose —
  # noctalia's theming writes generated files beside these; never manage
  # the whole dir.
  xdg.configFile."fuzzel/fuzzel.ini".source = ../../configs/fuzzel/fuzzel.ini;
  xdg.configFile."swaylock/config".source = ../../configs/swaylock/config;
  xdg.configFile."mpv/mpv.conf".source = ../../configs/mpv/mpv.conf;
  xdg.configFile."television/config.toml".source = ../../configs/television/config.toml;

  # ponytail: hand-rolled instead of programs.herdr — that HM module only
  # exists on home-manager's master branch, not the pinned release-26.05.
  xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml {}).generate "herdr-config" {
    onboarding = false;
    keys.prefix = "ctrl+a";
    ui.sound.enabled = false;
    ui.hide_tab_bar_when_single_tab = true;
  };
}
