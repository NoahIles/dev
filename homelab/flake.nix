{
  description = "Noah's homelab: NixOS LXC containers on Proxmox";

  # Same release as desktop/, locked to the same rev; no other inputs.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    host = name:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./modules/lxc.nix ./hosts/${name} {networking.hostName = name;}];
      };
  in {
    nixosConfigurations.apt-cacher-ng = host "apt-cacher-ng";
    nixosConfigurations.prowlarr = host "prowlarr";
    nixosConfigurations.radarr = host "radarr";
    nixosConfigurations.sonarr = host "sonarr";
  };
}
