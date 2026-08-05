{
  identity,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # ponytail: pkgs-unstable passed via extraSpecialArgs — was:
  # pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
  home.packages = with pkgs; [
    git
    mise
    nixd # Nix lsp
    sox # Sample Rate Converter for audio (claude code voice mode)
    lazygit
    tealdeer
    gitleaks # secret scanner, run by scripts/pre-push
    pkgs-unstable.herdr # agent multiplexer; stable nixpkgs doesn't ship it yet
    pkgs-unstable.codex # OpenAI (gipity) TUI AI Harnes
    pkgs-unstable.opencode # Open Source TUI AI Harness
    watchexec
  ];

  programs.git = {
    enable = true;
    settings.user.name = identity.fullName;
    settings.user.email = identity.email;
  };
}
