{
  description = "Noah's NixOS config profiles";

  # No inputs: this flake is a template registry only. Each subdirectory is a
  # self-contained flake pinning its own nixpkgs (desktop/ for the system,
  # devenv/ for dev shells).
  outputs = {self, ...}: {
    templates = {
      desktop = {
        path = ./desktop;
        description = "Bare-metal desktop: niri + noctalia, shared @home with CachyOS";
      };
    };

    defaultTemplate = self.templates.desktop;
  };
}
