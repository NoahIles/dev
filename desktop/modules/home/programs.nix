{
  config,
  identity,
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

  # HM's packages (ghostty, prismlauncher, …) drop icons into this profile's
  # share/icons/hicolor tree, but none of them supplies an index.theme — so
  # without this the tree isn't a valid icon theme and lookups fall through.
  # The system profile gets its hicolor index.theme from papirus instead.
  home.packages = [pkgs.hicolor-icon-theme];

  # also what puts git on PATH — it was separately listed in home.packages
  # before, which was redundant.
  programs.git = {
    enable = true;
    settings = {
      user.name = identity.fullName;
      user.email = identity.email;
      init.defaultBranch = "main";
      pull.rebase = true;
      merge.conflictStyle = "zdiff3";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      dark = true;
      line-numbers = true;
      hyperlinks = true;
      hyperlinks-file-link-format = "zed://file/{path}:{line}";
    };
  };

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
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
      "x-scheme-handler/chrome" = "helium.desktop";
      "text/html" = "helium.desktop";
      "application/x-extension-htm" = "helium.desktop";
      "application/x-extension-html" = "helium.desktop";
      "application/x-extension-shtml" = "helium.desktop";
      "application/xhtml+xml" = "helium.desktop";
      "application/x-extension-xhtml" = "helium.desktop";
      "application/x-extension-xht" = "helium.desktop";
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
