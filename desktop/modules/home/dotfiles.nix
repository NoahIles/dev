{
  config,
  lib,
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

  # vesktop's settings.json is mostly its own runtime state (plugin toggles,
  # cloud auth) — don't own the whole file, just make sure our theme is
  # enabled. Patches in place, leaves everything else untouched.
  home.activation.vesktopNoctaliaTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    f="$HOME/.config/vesktop/settings/settings.json"
    if [ -f "$f" ]; then
      ${pkgs.jq}/bin/jq '.enabledThemes = ((.enabledThemes // []) + ["noctalia.theme.css"] | unique)' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    fi
  '';
}
