{
  pkgs,
  pkgs-unstable,
  ink-md,
  ...
}: {
  # ponytail: pkgs-unstable passed via specialArgs — was:
  # pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
  environment.systemPackages = with pkgs; [
    sbctl # limine-sync.sh signs the ESP kernel (keys under /var/lib/sbctl)
    just # command runner (~/nixos/Justfile)
    alejandra # rebuild.sh formats *.nix
    nvd # rebuild.sh diffs generations before switching
    delta
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
    gh

    # dev
    mise
    nixd # Nix lsp
    sox # Sample Rate Converter for audio (claude code voice mode)
    lazygit
    tealdeer
    gitleaks # secret scanner, run by scripts/pre-push
    watchexec
    pkgs-unstable.herdr # agent multiplexer; stable nixpkgs doesn't ship it yet
    pkgs-unstable.codex # OpenAI (gipity) TUI AI Harnes
    pkgs-unstable.opencode # Open Source TUI AI Harness
    glow # TUI markdown renderer
    ink-md # borghei/ink: fancier TUI markdown reader (images, mermaid, themes)
  ];
}
