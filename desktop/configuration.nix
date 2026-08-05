{
  identity,
  inputs,
  pkgs,
  ...
}: {
  networking.hostName = identity.hostName;
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.registry = {
    stable.flake = inputs.nixpkgs;
    unstable.flake = inputs.nixpkgs-unstable;
  };
  nixpkgs.config.allowUnfree = true; # nvidia, steam, zed extensions etc.
  # flakes (nix shell/run/build) ignore nixpkgs.config; this covers those

  programs.fish.enable = true;

  # shared @home has AppImages (~/.local/bin) and CachyOS-built binaries
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.nix-ld.enable = true;

  system.stateVersion = "25.05";
}
