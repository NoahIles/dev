{
  description = "Noah's NixOS config profiles";

  outputs = { self }: {

    templates = {

      default = {
        path = ./default;
        description = "Bare-metal desktop: niri + noctalia, shared @home with CachyOS";
      };

    };

    defaultTemplate = self.templates.default;

  };
}
