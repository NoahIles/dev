# dev#14 phase 1: replaces Ubuntu VM 100 (ubu-1, .100). Compose stacks are kept
# as they are in the same directories; this host only provides docker, the
# users with the old uids/gids (bind-dir ownership survives rsync) and the git
# remote. See llm-wiki homelab/vm-conversion.md.
{
  pkgs,
  lib,
  ...
}: {
  virtualisation.docker.enable = true;

  # gids/uids copied from the Ubuntu box. NixOS pins docker to gid 131; force the old one.
  users.groups = {
    noah.gid = 1000;
    docker.gid = lib.mkForce 1001;
    minecraft_admin.gid = 1002;
    minecraft.gid = 1003;
  };
  users.users.noah = {
    isNormalUser = true;
    uid = 1000;
    group = "noah";
    extraGroups = ["docker" "minecraft_admin" "wheel"];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIU1uc0u1NhjQ9e4pJKrHWQWWdkfkNbKVAZ2CHyuM5bS noahiles@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1ZB2LANb2hD3MHbLLmwqbc/8UkV3IPvWgK/Jm4ZhtO Noahiles@gmail.com"
    ];
  };
  users.users.minecraft = {
    isNormalUser = true;
    uid = 1001;
    group = "minecraft";
    extraGroups = ["docker" "minecraft_admin"];
    shell = pkgs.bash;
  };
  programs.fish.enable = true;

  # The wiki and nixos remotes are plain ssh to noah@ubu-1:/srv/git/*.git, so
  # git must be on the non-interactive PATH. Repos are rsynced in, not created.
  environment.systemPackages = [pkgs.git pkgs.rsync];
  systemd.tmpfiles.rules = ["d /srv/git 0755 noah noah -"];

  # docker publishes through its own NAT chain; these document the ports.
  networking.firewall = {
    allowedTCPPorts = [25565 25566 7777 8888];
    allowedUDPPorts = [7777];
  };

  system.stateVersion = "26.05";
}
