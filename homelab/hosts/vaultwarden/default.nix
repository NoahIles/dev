{
  # No secrets to carry over: the old CT's ADMIN_TOKEN is empty (admin panel off).
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://vw.nislands.xyz";
      # Same port as the Debian CT, so the Caddy upstream only changes host.
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8000;
    };
  };

  networking.firewall.allowedTCPPorts = [8000];

  system.stateVersion = "26.05";
}
