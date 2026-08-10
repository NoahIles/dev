{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  # one name for gtk (noctalia reads this one) and both qtct configs.
  # package comes from environment.systemPackages in modules/desktop.nix.
  iconTheme = "Papirus-Dark";
in {
  # Everything HM *generates*. If a setting lives here, edit the Nix and
  # rebuild — hand-editing the file in ~/.config gets clobbered. The
  # symlink lane (edit the file directly, hot-reloads) is dotfiles.nix.

  programs.television = {
    enableFishIntegration = true;
    enable = true;
    # Must match the pin in modules/cli.nix (0.15.9, multi-command source
    # schema). Without this the HM per-user profile shadows the system
    # profile on PATH and you silently get stable instead.
    package = pkgs-unstable.television;
  };

  programs.nix-search-tv = {
    enable = true;
    enableTelevisionIntegration = true;
  };

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
  };

  programs.alacritty = {
    enable = true;
    #theme = "noctalia";
  };

  programs.prismlauncher = {
    enable = true;
    extraPackages = [];
    settings = {
      ApplicationTheme = "Dark";
      EnableFeralGamemode = "false";
      MaxMemAlloc = 4095;
      Language = "en_US";
      PermGen = 255;
      CloseAfterLaunch = true;
    };
  };

  home.pointerCursor = {
    name = "catppuccin-mocha-mauve-cursors";
    size = 24;
    package = pkgs.catppuccin-cursors.mochaMauve;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      name = "SF Pro Display";
      size = 12;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme.name = iconTheme;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.package = [
      pkgs.adwaita-qt
      pkgs.adwaita-qt6
    ];

    qt5ctSettings.Appearance = {
      style = "Adwaita-Dark";
      custom_palette = true;
      color_scheme_path = "${config.xdg.configHome}/qt5ct/colors/noctalia.conf";
      icon_theme = iconTheme;
      standard_dialogs = "xdgdesktopportal";
    };

    qt6ctSettings.Appearance = {
      style = "Adwaita-Dark";
      custom_palette = true;
      color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/noctalia.conf";
      icon_theme = iconTheme;
      standard_dialogs = "xdgdesktopportal";
    };
  };

  xdg.configFile."mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/chrome" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/nxm" = "mo2lint_nxm-handler.desktop";
      "text/plain" = "dev.zed.Zed.desktop";
      "application/toml" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";
      "application/json" = "dev.zed.Zed.desktop";
      "application/x-shellscript" = "dev.zed.Zed.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
      "application/epub+zip" = "org.pwmt.zathura.desktop";
      "application/postscript" = "org.pwmt.zathura.desktop";
      "application/x-cb7" = "org.pwmt.zathura.desktop";
      "application/x-cbr" = "org.pwmt.zathura.desktop";
      "application/x-cbt" = "org.pwmt.zathura.desktop";
      "application/x-cbz" = "org.pwmt.zathura.desktop";
      "image/vnd.djvu" = "org.pwmt.zathura.desktop";
      "image/jpeg" = "imv-dir.desktop";
      "image/png" = "imv-dir.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "application/zip" = "org.gnome.Nautilus.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };

  # legacy nix commands (nix-env, nix-build, nix-shell -p) read this; flake
  # commands (nix shell nixpkgs#pkg) don't and still need --impure
  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";

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
