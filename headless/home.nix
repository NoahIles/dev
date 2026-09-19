{
  identity,
  inputs,
  config,
  ...
}: let
  live = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/desktop/configs/${name}";
  };
in {
  # The Claude setup itself: live-lane links into ~/nixos (docs/adr/0002).
  # Needs ~/nixos and ~/Documents/llm-wiki cloned before the first switch.
  imports = ["${inputs.desktop}/modules/home/claude.nix"];

  home.username = identity.username;
  home.homeDirectory = identity.homeDirectory;
  home.stateVersion = "26.05";

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

  # Same shell as the desktop, from the same files.
  xdg.configFile."fish" = live "fish";
  xdg.configFile."starship.toml" = (live "starship/starship.toml") // {force = true;};
}
