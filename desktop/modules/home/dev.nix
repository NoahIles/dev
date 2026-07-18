{
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
in {
  home.packages = with pkgs; [
    git
    mise
    nixd # Nix lsp
    sox # Sample Rate Converter for audio (claude code voice mode)
    lazygit
    tealdeer
    gitleaks # secret scanner, run by scripts/pre-push
    pkgs-unstable.herdr # agent multiplexer; stable nixpkgs doesn't ship it yet
  ];

  programs.git = {
    enable = true;
    settings.user.name = "Noah Iles";
    settings.user.email = "git@nislands.xyz";
  };
}
