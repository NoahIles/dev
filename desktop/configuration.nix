{pkgs, ...}: {
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true; # nvidia, steam, zed extensions etc.
  # flakes (nix shell/run/build) ignore nixpkgs.config; this covers those
  environment.variables.NIXPKGS_ALLOW_UNFREE = "1";

  programs.fish.enable = true;

  # shared @home has AppImages (~/.local/bin) and CachyOS-built binaries
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.nix-ld.enable = true;

  system.stateVersion = "25.05";
}
