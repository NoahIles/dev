{
  description = "Noah's NixOS config — niri + noctalia";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apple SF fonts ("SF Hello" = SF Pro). Not in nixpkgs — proprietary.
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    pkgs-unstable = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    sharedModules = [
      ./configuration.nix
      ./modules/desktop.nix
      ./modules/cli.nix
      ./modules/performance.nix
      ./modules/fonts.nix
      ./modules/ssh.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit inputs pkgs-unstable;
          _isVM = false;
        };
        home-manager.users.noah = import ./home.nix;
      }
    ];
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs pkgs-unstable;};
      modules =
        sharedModules
        ++ [
          ./modules/boot.nix
          ./modules/gaming.nix
          ./modules/udev-wootility.nix
          ./hardware-configuration.nix
        ];
    };

    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs pkgs-unstable;};
      modules = sharedModules ++ [./vm.nix];
    };
  };
}
