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
      # ponytail: needs ffmpeg_9, not in nixos-26.05
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

    # borghei/ink has no flake of its own — this is our packaging fork
    # (NoahIles/ink), synced from upstream monthly by its own CI.
    ink.url = "github:NoahIles/ink";

    # wooting-bg-service isn't in nixpkgs yet — tracking the open,
    # unmerged nixpkgs PR (NixOS/nixpkgs#529138) as a temporary input.
    # Delete this input once that PR merges and switch back to nixpkgs.
    wooting-nixpkgs.url = "github:hustlerone/nixpkgs-kmscon-no-drm/wooting";
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    identity = import ./identity.nix;
    pkgs-unstable = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    ink-md = inputs.ink.packages.x86_64-linux.default;
    pkgs-wooting = import inputs.wooting-nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    sharedModules = [
      ./configuration.nix
      ./modules/desktop.nix
      ./modules/apps.nix
      ./modules/cli.nix
      ./modules/performance.nix
      ./modules/fonts.nix
      ./modules/identity.nix
      ./modules/ssh.nix
      home-manager.nixosModules.home-manager
      {
        # Ties each generation back to the commit it was built from; shows up
        # in `nixos-rebuild list-generations`. See docs/adr/0001.
        system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or "dirty";

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Live-lane dotfiles are symlinks back into this repo; if something
        # replaces one with a real file, activation would abort. Back it up
        # and carry on instead of forcing (force silently eats hand-edits
        # that never made it to git).
        home-manager.backupFileExtension = "hm-bak";
        home-manager.extraSpecialArgs = {
          inherit identity inputs pkgs-unstable;
          _isVM = false;
        };
        home-manager.users.${identity.username} = import ./home.nix;
      }
    ];
  in {
    # DESKTOP
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit identity inputs pkgs-unstable ink-md pkgs-wooting;};
      modules =
        sharedModules
        ++ [
          ./modules/boot.nix
          ./modules/gaming.nix
          ./modules/wootility.nix
          ./modules/hardware.nix
        ];
    };
    # VM
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit identity inputs pkgs-unstable ink-md;};
      modules = sharedModules ++ [./vm.nix];
    };
  };
}
