{
  identity,
  lib,
  inputs,
  pkgs,
  ...
}: {
  networking.hostName = identity.hostName;
  networking.networkmanager.enable = true;
  # Networks joined by hand (`zerotier-cli join <id>`); joinNetworks would bake
  # the ID into the world-readable nix store.
  services.zerotierone.enable = true;
  # Don't start at boot.
  systemd.services.zerotierone.wantedBy = lib.mkForce [];
  # ponytail: the button can't show state (custom_button is static), so the
  # notification is the feedback. A live indicator needs a scripted plugin.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "zt-toggle" ''
      if systemctl is-active --quiet zerotierone; then
        sudo systemctl stop zerotierone && noctalia msg notification-show ZeroTier disconnected
      else
        sudo systemctl start zerotierone && noctalia msg notification-show ZeroTier connected
      fi
    '')
  ];
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

  # ShadowPlay-style replay buffer; module handles the setcap wrapper
  programs.gpu-screen-recorder.enable = true;

  system.stateVersion = "25.05";
}
