{
  description = "Noah's homelab: NixOS LXC containers on Proxmox";

  # Same release as desktop/, locked to the same rev; no other inputs.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    host = base: name:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./modules/${base}.nix ./hosts/${name} {networking.hostName = name;}];
      };
  in {
    nixosConfigurations.apt-cacher-ng = host "lxc" "apt-cacher-ng";
    nixosConfigurations.prowlarr = host "lxc" "prowlarr";
    nixosConfigurations.radarr = host "lxc" "radarr";
    nixosConfigurations.sonarr = host "lxc" "sonarr";
    nixosConfigurations.qbittorrent = host "lxc" "qbittorrent";
    nixosConfigurations.headscale = host "lxc" "headscale";
    nixosConfigurations.docker-test = host "vm" "docker-test";
  };
}
