# niri — the daily-driver compositor. Its session file, portal and xwayland
# wiring all come from the nixpkgs module; config lives in configs/niri/.
{...}: {
  programs.niri.enable = true;
}
