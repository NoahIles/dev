{
  pkgs,
  inputs,
  ...
}: let
  # television 0.15.7+ is needed for the multi-command [source] channel schema
  # used by ~/.config/television/cable/*.toml; stable (26.05) still ships 0.15.6.
  pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
in {
  environment.systemPackages = with pkgs; [
    sbctl # limine-sync.sh signs the ESP kernel (keys under /var/lib/sbctl)
    alejandra # rebuild.sh formats *.nix
    eza # Ls replacement
    starship # Terminal Prompt
    zoxide # cd replacement
    bat # cat replacement
    duf # du for filesystems
    dust # du repalcement
    trashy # rm replacement
    fd # Better find
    fzf # Fuzzy Finder
    pkgs-unstable.television # fuzzy finder (unstable: 0.15.9, supports multi-command source schema)
    ripgrep # Ripgrep
    jq # filter json

    vim # better nano
    helix # better vim?
    claude-code
  ];
}
