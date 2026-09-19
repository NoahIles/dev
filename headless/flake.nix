{
  description = "Noah's headless NixOS — CLI host for NixOS-WSL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # borghei/ink packaging fork — cli.nix installs it
    ink.url = "github:NoahIles/ink";

    # Modules shared with desktop/: source only, never evaluated as a flake.
    # Re-lock after touching the files this pulls in (cli.nix, identity.nix,
    # modules/home/claude.nix): nix flake lock --update-input desktop
    desktop = {
      url = "path:../desktop";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixos-wsl,
    ...
  } @ inputs: let
    identity =
      (import "${inputs.desktop}/identity.nix")
      // {
        hostName = "NixWsl";
      };
    pkgs-unstable = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    ink-md = inputs.ink.packages.x86_64-linux.default;
  in {
    nixosConfigurations.NixWsl = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit identity inputs pkgs-unstable ink-md;};
      modules = [
        nixos-wsl.nixosModules.default
        ./configuration.nix
        # same package set as the desktop — subtract here if it ever bloats
        "${inputs.desktop}/modules/cli.nix"
        home-manager.nixosModules.home-manager
        {
          system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or "dirty";

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.extraSpecialArgs = {inherit identity inputs pkgs-unstable;};
          home-manager.users.${identity.username} = import ./home.nix;
        }
      ];
    };
  };
}
