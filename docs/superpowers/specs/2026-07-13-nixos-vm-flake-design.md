# NixOS flake for niri + noctalia VM trial

**Goal:** Prepare a NixOS config flake including Noah's current niri and
noctalia configs, testable in a VM before any bare-metal install.

**Decisions:**
- Keep the starter-template layout: root flake.nix is a template registry;
  each folder (`default/`, later others) is a self-contained config flake.
- Plain nixpkgs `programs.niri` module + home-manager. No niri-flake kdl→nix
  rewrite; raw dotfiles shipped as-is.
- Inputs: nixpkgs-unstable, home-manager, noctalia-shell flake, zen-browser
  flake (not in nixpkgs).
- Packages: fish, ghostty, alacritty, zed-editor, zen-browser, git, mise,
  plus niri runtime deps (fuzzel, swaylock, brightnessctl, playerctl, jq,
  wl-clipboard, nautilus).
- Dotfiles copied on HM activation (not symlinked): noctalia rewrites
  settings.json and niri/noctalia.kdl at runtime.
- VM host `vm`: stub fileSystems/bootloader, greetd autologin into
  niri-session, pipewire, `virtualisation.vmVariant` with virtio-gpu GL.
- Noctalia dotfiles limited to the 4 small files; colorschemes/plugins dirs
  (6.5MB) are fetched at runtime.

**Deferred:** real hardware host, nix not yet installed on CachyOS (needed to
run the VM test).
