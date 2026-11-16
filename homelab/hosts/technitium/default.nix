{lib, ...}: {
  services.technitium-dns-server = {
    enable = true;
    # Open only what 115 actually listens on (53, 5380 HTTP, DHCP 67); no
    # DoH/DoT/HTTPS-admin there, so 53443 stays closed.
    openFirewall = true;
    firewallTCPPorts = [53 5380];
    firewallUDPPorts = [53 67];
  };

  # DHCP needs raw sockets (ICMP conflict probe) beyond the module's
  # NET_BIND_SERVICE-only set.
  systemd.services.technitium-dns-server.serviceConfig = {
    AmbientCapabilities = lib.mkForce ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
    CapabilityBoundingSet = lib.mkForce ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
  };

  # base.nix points guests at 192.168.1.115; this host IS the resolver once it
  # takes that IP, so resolve through ourselves.
  networking.nameservers = lib.mkForce ["127.0.0.1"];

  # resolved's stub listens on 127.0.0.53/.54 port 53 (TCP too), which blocks
  # Technitium's 0.0.0.0:53 TCP bind: v4 TCP DNS was refused until this was off.
  services.resolved.settings.Resolve.DNSStubListener = "no";

  system.stateVersion = "26.05";
}
