{pkgs-unstable, ...}: {
  programs.television = {
    enableFishIntegration = true;
    enable = true;
    # Must match the pin in modules/cli.nix (0.15.9, multi-command source
    # schema). Without this the HM per-user profile shadows the system
    # profile on PATH and you silently get stable instead.
    package = pkgs-unstable.television;
  };

  programs.nix-search-tv = {
    enable = true;
    enableTelevisionIntegration = true;
  };

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
  };

  programs.alacritty = {
    enable = true;
    #theme = "noctalia";
  };
}
