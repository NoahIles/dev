{
  config,
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
  # live-lane dotfiles: symlink to the repo checkout (not the store) so
  # hand-edits hot-reload and GUI writes land as git diffs. Dangles if the
  # repo isn't at ~/nixos — programs then fall back to defaults.
  configsDir = "${config.home.homeDirectory}/nixos/desktop/configs";
  live = name: {source = config.lib.file.mkOutOfStoreSymlink "${configsDir}/${name}";};
in {
  home.username = "noah";
  home.homeDirectory = "/home/noah";
  home.stateVersion = "25.05";

  # ponytail: @home is shared with CachyOS, so most of ~/.config stays
  # canonical/loose (niri, noctalia, fish, …). ghostty + herdr are the first
  # dotfiles migrated to be HM-managed — more will follow over time.
  home.packages = with pkgs; [
    # apps
    imv # Image viewer
    zed-editor # Text editor
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    spotify
    pkgs-unstable.mailspring
    # flake ships the binary as `zen-beta`; alias it so `zen-browser` (used by
    # niri keybinds) resolves. This is the official stable Zen release.
    (pkgs.writeShellScriptBin "zen-browser" ''exec zen-beta "$@"'')
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default # Shell
    (pkgs.writeShellScriptBin "game-performance" ''exec gamemoderun "$@"'')
    (jellyfin-desktop.overrideAttrs (old: {
      # ponytail: NVIDIA + native Wayland fails to composite mpv's embedded
      # video surface (white screen on playback) — force XWayland instead.
      qtWrapperArgs = old.qtWrapperArgs ++ ["--set QT_QPA_PLATFORM xcb"];
    }))

    vesktop

    # dev

    git
    mise
    nixd # Nix lsp
    sox # Sample Rate Converter for audio (claude code voice mode)
    lazygit
    tealdeer
    gitleaks # secret scanner, run by scripts/pre-push

    # niri config runtime deps
    pavucontrol
    fuzzel
    swaylock
    brightnessctl
    playerctl
    wl-clipboard
    nautilus
    xwayland-satellite
    teamspeak6-client
    tailscale

    pkgs-unstable.herdr # agent multiplexer; stable nixpkgs doesn't ship it yet
  ];

  programs.television = {
    enableFishIntegration = true;
    enable = true;
  };

  programs.nix-search-tv = {
    enable = true;
    enableTelevisionIntegration = true;
  };

  programs.git = {
    enable = true;
    settings.user.name = "Noah Iles";
    settings.user.email = "git@nislands.xyz";
  };

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;

    settings = {
      alpha-blending = "linear-corrected";
      theme = "noctalia";
      window-padding-x = 1;
      #background-opacity = 50;
      #background-blur = 0;
      confirm-close-surface = false;
      #shell-integration = "fish";
      #command = "herdr";
      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "ctrl+enter=ignore"
        "ctrl+shift+d=scroll_page_fractional:0.5"
        "ctrl+shift+u=scroll_page_fractional:-0.5"
      ];
    };
  };

  programs.alacritty = {
    enable = true;
    #theme = "noctalia";
  };

  # ponytail: hand-rolled instead of programs.herdr — that HM module only
  # exists on home-manager's master branch, not the pinned release-26.05.
  xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml {}).generate "herdr-config" {
    onboarding = false;
    keys.prefix = "ctrl+a";
    ui.sound.enabled = false;
    ui.hide_tab_bar_when_single_tab = true;
  };

  xdg.configFile."niri" = live "niri";
  xdg.configFile."noctalia" = live "noctalia";
  xdg.configFile."fish" = live "fish";
  xdg.configFile."zed" = live "zed";
}
