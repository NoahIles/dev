{
  identity,
  pkgs,
  ...
}: {
  wsl = {
    enable = true;
    defaultUser = identity.username;
    # ponytail: everything else is NixOS-WSL's default — interop, /mnt/c and
    # systemd already come out of the box.
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = identity.hostName;
  time.timeZone = "America/Los_Angeles";

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
  users.users.${identity.username} = {
    shell = pkgs.fish;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = identity.sshKeys;
  };

  # cli.nix covers the rest; these are the ones a headless host needs on its
  # own — curl bootstraps the native `claude` installer, which is where the
  # binary comes from (docs/adr/0002).
  environment.systemPackages = with pkgs; [git curl];

  system.stateVersion = "26.05";
}
