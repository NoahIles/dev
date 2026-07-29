{...}: {
  programs.television = {
    enableFishIntegration = true;
    enable = true;
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
