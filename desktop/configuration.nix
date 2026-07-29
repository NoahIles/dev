{pkgs, ...}: {
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true; # nvidia, steam, zed extensions etc.
  # flakes (nix shell/run/build) ignore nixpkgs.config; this covers those
  environment.variables.NIXPKGS_ALLOW_UNFREE = "1";

  # ponytail: initialPassword only applies if the user is created fresh;
  # set a real one with `passwd` on first boot.
  users.users.noah = {
    isNormalUser = true;
    uid = 1000; # must match CachyOS uid for shared @home
    extraGroups = ["wheel" "networkmanager" "video" "gamemode"];
    shell = pkgs.fish;
    initialPassword = "noah";
  };
  programs.fish.enable = true;

  # shared @home has AppImages (~/.local/bin) and CachyOS-built binaries
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.nix-ld.enable = true;

  # let rebuild.sh run without a password (also lets Claude Code rebuild —
  # its shell has no TTY and no logind session, so sudo/pkexec can't prompt)
  security.sudo.extraRules = [
    {
      users = ["noah"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  system.stateVersion = "25.05";
}
