{
  pkgs,
  pkgs-unstable,
  ...
}: {
  # ponytail: pkgs-unstable passed via specialArgs — was:
  # pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
  environment.systemPackages = with pkgs; [
    sbctl # limine-sync.sh signs the ESP kernel (keys under /var/lib/sbctl)
    just # command runner (~/nixos/Justfile)
    alejandra # rebuild.sh formats *.nix
    nvd # rebuild.sh diffs generations before switching
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
    pkgs-unstable.claude-code
  ];
}
