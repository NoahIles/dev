{
  pkgs,
  inputs,
  ...
}: {
  fonts.packages = with pkgs; [
    inter
    nerd-fonts.hack # Currently used by alacrity
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka-term
    inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro # Default System font
  ];

  # Pin defaults so the generic aliases don't drift when the font set /
  # cache is rebuilt (this is why the font changed after a reboot).
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["SF Pro Display" "SF Pro Text" "Inter"];
    monospace = ["JetBrainsMono Nerd Font"];
  };
}
