{pkgs-unstable, ...}: {
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  services.ananicy = {
    enable = true;
    package = pkgs-unstable.ananicy-cpp;
    rulesProvider = pkgs-unstable.ananicy-rules-cachyos;
  };

  # sched-ext userspace scheduler; scx_lavd is provided by rustscheds.
  services.scx = {
    enable = true;
    package = pkgs-unstable.scx.full;
    scheduler = "scx_lavd";
  };
}
