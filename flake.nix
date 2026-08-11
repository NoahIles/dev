{
  description = "Noah's NixOS config profiles";

  outputs = {self}: {
    templates = {
      desktop = {
        path = ./desktop;
        description = "Bare-metal desktop: niri + noctalia, shared @home with CachyOS";
      };
    };

    defaultTemplate = self.templates.desktop;
  };
}
