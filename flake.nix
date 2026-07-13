{
  description = "Noah's NixOS config profiles";

  outputs = { self }: {

    templates = {

      default = {
        path = ./default;
        description = "Bare-metal desktop: niri + noctalia, shared @home with CachyOS";
      };

      vm = {
        path = ./vm;
        description = "QEMU trial VM: niri + noctalia with bundled dotfiles";
      };

    };

    defaultTemplate = self.templates.default;

  };
}
