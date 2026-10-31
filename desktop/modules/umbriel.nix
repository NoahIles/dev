# Umbriel — noctalia-dev's wlroots compositor, offered as a second session in
# the greeter next to niri. Drop the import from flake.nix to remove it; the
# user config in configs/umbriel/ then does nothing.
{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.umbriel.nixosModules.default];

  # Session file, portal (umbriel + gtk), and the share/umbriel/effects link.
  programs.umbriel.enable = true;

  # Builds only match the cache against upstream's own locked nixpkgs, so the
  # input has no nixpkgs.follows (same deal as noctalia).
  nix.settings = {
    extra-substituters = ["https://umbriel.cachix.org"];
    extra-trusted-public-keys = ["umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="];
  };

  environment.systemPackages = with pkgs; [
    bitwarden-cli # Used by noctalia plugin
  ];
}
