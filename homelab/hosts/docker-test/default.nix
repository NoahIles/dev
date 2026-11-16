# dev#9: proves a NixOS VM runs an existing compose stack unchanged.
{
  virtualisation.docker.enable = true;

  system.stateVersion = "26.05";
}
