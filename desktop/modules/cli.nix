{
  pkgs,
  pkgs-unstable,
  ...
}: let
  # ink-md: not in nixpkgs yet (young repo, custom license blocks upstreaming).
  ink-md = pkgs.rustPlatform.buildRustPackage rec {
    pname = "ink-md";
    version = "0.6.7";
    src = pkgs.fetchFromGitHub {
      owner = "borghei";
      repo = "ink";
      rev = "v${version}";
      hash = "sha256-9ON7KgYmGRlLJPUDkIa27/4VXfq09Y36xQSi59E7Bmg=";
    };
    cargoHash = "sha256-A3/fqSrHixMfKukEwZ2LSKl4d1e+2iGS+WTK76uMm/Q=";
    meta = with pkgs.lib; {
      description = "Terminal markdown reader with syntax highlighting, inline images, and mermaid diagrams";
      homepage = "https://github.com/borghei/ink";
      license = licenses.unfree; # custom source-available license, free-to-use but no resale
      mainProgram = "ink";
    };
  };
in {
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
