{
  lib,
  pkgs,
  ...
}: {
  # State (db.sqlite + noise_private.key) lives in /var/lib/headscale and is
  # copied from the Debian CT at cutover; the key must survive or every node
  # re-registers. server_url must stay the same for the same reason.
  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8080;
    settings = {
      server_url = "https://vpn.nislands.xyz";
      dns = {
        magic_dns = true;
        base_domain = "example.com";
        override_local_dns = true;
        nameservers.global = ["1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"];
      };
      disable_check_updates = lib.mkForce false;
      derp.update_frequency = "3h";
      taildrop.enabled = true;
      node = {
        expiry = "0";
        ephemeral.inactivity_timeout = "30m";
        routes.ha = {
          probe_interval = "10s";
          probe_timeout = "5s";
        };
      };
      policy.path = pkgs.writeText "policy.hujson" ''
        {
          "acls": [
            { "action": "accept", "src": ["noah@", "seth@", "shawn@"], "dst": ["services@:*"] }
          ]
        }
      '';
    };
  };

  # The edge Caddy upstream is <host>:80, as it was on the Debian CT (which ran
  # its own Caddy). ponytail: the /admin web UI (headscale-admin) is not ported.
  services.caddy = {
    enable = true;
    virtualHosts.":80".extraConfig = "reverse_proxy 127.0.0.1:8080";
  };
  networking.firewall.allowedTCPPorts = [80];

  system.stateVersion = "26.05";
}
