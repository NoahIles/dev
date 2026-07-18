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

    settings = {
      alpha-blending = "linear-corrected";
      theme = "noctalia";
      window-padding-x = 1;
      #background-opacity = 50;
      #background-blur = 0;
      confirm-close-surface = false;
      #shell-integration = "fish";
      #command = "herdr";
      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "ctrl+enter=ignore"
        "ctrl+shift+d=scroll_page_fractional:0.5"
        "ctrl+shift+u=scroll_page_fractional:-0.5"
      ];
    };
  };

  programs.alacritty = {
    enable = true;
    #theme = "noctalia";
  };
}
