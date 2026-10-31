{
  identity,
  inputs,
  ...
}: {
  imports = [
    ./modules/home/programs.nix
    ./modules/home/dotfiles.nix
    ./modules/home/claude.nix
    ./modules/home/noctalia.nix
    inputs.noctalia.homeModules.default
  ];

  home.username = identity.username;
  home.homeDirectory = identity.homeDirectory;
  home.stateVersion = "26.05";

  # ponytail: @home is shared with CachyOS, so most of ~/.config stays
  # canonical/loose (niri, fish, …) via the live-lane symlinks in
  # modules/home/dotfiles.nix; migration to HM-managed files is piecemeal.
  # Noctalia's settings already moved: see modules/home/noctalia.nix.

  # ShadowPlay-style replay buffer. The F24 bind in configs/niri/keybinds.kdl
  # flushes it with SIGUSR1; -sc runs gsr-save-hook on the saved file.
  # ponytail: hardcoded to DP-1 (the ultrawide) — swap to -w DP-2 or add a
  # second unit if the other monitor ever needs it.
  systemd.user.services.gpu-screen-recorder = {
    Unit = {
      Description = "gpu-screen-recorder replay buffer";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "/run/current-system/sw/bin/gpu-screen-recorder -w DP-1 -f 60 -r 60 -c mp4 -a default_output -replay-storage ram -o %h/Videos/clips -sc %h/.config/niri/scripts/gsr-save-hook";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
