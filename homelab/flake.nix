{
  description = "Noah's homelab: NixOS LXC containers on Proxmox";

  # Same release as desktop/, locked to the same rev; no other inputs.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  # Only for hosts/jellyfin: the old CT runs Jellyfin 12.x, stable ships 10.11.x
  # and the DB migration is one-way. Drop once nixos-26.05 carries Jellyfin 12.
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    ...
  }: let
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
    nixosConfigurations.vaultwarden = host "lxc" "vaultwarden";
    nixosConfigurations.qbittorrent = host "lxc" "qbittorrent";
    nixosConfigurations.headscale = host "lxc" "headscale";
    nixosConfigurations.technitium = host "lxc" "technitium";
    nixosConfigurations.docker-test = host "vm" "docker-test";
    nixosConfigurations.ubu-1 = host "vm" "ubu-1";
    nixosConfigurations.jellyfin = (host "lxc" "jellyfin").extendModules {
      specialArgs.unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
    };
  };
}
